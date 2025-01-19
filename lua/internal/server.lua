local client_capabilities = {}
local projects = {}

-- Default configuration for Phoenix
local default = {
  filetypes = { '*' },
  -- Dictionary related settings
  dict = {
    -- Maximum number of words to store in the dictionary
    -- Higher values consume more memory but provide better completions
    max_words = 50000,

    -- Minimum word length to be considered for completion
    -- Shorter words may create noise in completions
    min_word_length = 2,
    -- Time factor weight for sorting completions (0-1)
    -- Higher values favor recently used items more strongly
    recency_weight = 0.3,

    -- Base weight for frequency in sorting (0-1)
    -- Complements recency_weight, should sum to 1
    frequency_weight = 0.7,
  },

  -- Performance related settings
  scan = {
    cache_ttl = 5000,
    -- Number of items to process in each batch
    -- Higher values improve speed but may cause stuttering
    batch_size = 1000,
    -- Ignored the file or dictionary which matched the pattern
    ignore_patterns = {},

    -- Throttle delay for dictionary updates in milliseconds
    -- Prevents excessive CPU usage during rapid file changes
    throttle_ms = 100,
  },
}

local cfg = setmetatable({}, {
  __index = function(_, scope)
    return vim.tbl_get(vim.g.phoenix or default, scope)
  end,
})

local Trie = {}
function Trie.new()
  return {
    children = {},
    is_end = false,
    frequency = 0,
    last_used = 0, -- timestamp for LRU-based cleanup
  }
end

function Trie.insert(root, word, timestamp)
  local node = root
  for i = 1, #word do
    local char = word:sub(i, i)
    node.children[char] = node.children[char] or Trie.new()
    node = node.children[char]
  end
  local was_new = not node.is_end
  node.is_end = true
  node.frequency = node.frequency + 1
  node.last_used = timestamp
  return was_new
end

function Trie.search_prefix(root, prefix)
  local node = root
  for i = 1, #prefix do
    local char = prefix:sub(i, i)
    if not node.children[char] then
      return {}
    end
    node = node.children[char]
  end

  local results = {}
  local function collect_words(current_node, current_word)
    if current_node.is_end then
      table.insert(results, {
        word = current_word,
        frequency = current_node.frequency,
        last_used = vim.uv.now(),
      })
    end

    for char, child in pairs(current_node.children) do
      collect_words(child, current_word .. char)
    end
  end

  collect_words(node, prefix)
  return results
end

local dict = {
  trie = Trie.new(),
  word_count = 0,
  max_words = cfg.dict.max_words,
  min_word_length = cfg.dict.min_word_length,
}

-- LRU cache
local LRUCache = {}

-- Node constructor
local function new_node(key, value)
  return { key = key, value = value, prev = nil, next = nil }
end

function LRUCache:new(max_size)
  local obj = {
    cache = {},
    head = nil,
    tail = nil,
    max_size = max_size or 100,
    size = 0,
  }
  setmetatable(obj, self)
  self.__index = self
  return obj
end

-- Move node to the head of the list
function LRUCache:move_to_head(node)
  if node == self.head then
    return
  end
  self:remove(node)
  self:add_to_head(node)
end

-- Add node to the head of the list
function LRUCache:add_to_head(node)
  node.next = self.head
  node.prev = nil
  if self.head then
    self.head.prev = node
  end
  self.head = node
  if not self.tail then
    self.tail = node
  end
  self.size = self.size + 1
end

-- Remove node from the list
function LRUCache:remove(node)
  if node.prev then
    node.prev.next = node.next
  else
    self.head = node.next
  end
  if node.next then
    node.next.prev = node.prev
  else
    self.tail = node.prev
  end
  self.size = self.size - 1
end

-- Remove the tail node
function LRUCache:remove_tail()
  if not self.tail then
    return nil
  end
  local tail_node = self.tail
  self:remove(tail_node)
  return tail_node
end

-- Get the value of a key
function LRUCache:get(key)
  local node = self.cache[key]
  if not node then
    return nil
  end
  self:move_to_head(node)
  return node.value
end

-- Put a key-value pair into the cache
function LRUCache:put(key, value)
  local node = self.cache[key]
  if node then
    node.value = value
    self:move_to_head(node)
  else
    if self.size >= self.max_size then
      local tail_node = self:remove_tail()
      if tail_node then
        self.cache[tail_node.key] = nil
      end
    end
    local newNode = new_node(key, value)
    self:add_to_head(newNode)
    self.cache[key] = newNode
  end
end

local scan_cache = LRUCache:new(100)

local async = {}

function async.throttle(fn, delay)
  local timer = nil
  return function(...)
    local args = { ... }
    if timer and not timer:is_closing() then
      timer:stop()
      timer:close()
    end
    timer = assert(vim.uv.new_timer())
    timer:start(
      delay,
      0,
      vim.schedule_wrap(function()
        timer:stop()
        timer:close()
        fn(unpack(args))
      end)
    )
  end
end

local server = {}

local function get_root(filename)
  local data
  for r, item in pairs(projects) do
    if vim.startswith(filename, r) then
      data = item
      break
    end
  end
  return data
end

local function schedule_result(callback, items)
  vim.schedule(function()
    callback(nil, { isIncomplete = false, items = items or {} })
  end)
end

local function scan_dir_async(path, callback)
  local cached = scan_cache:get(path)
  if cached and (vim.uv.now() - cached.timestamp) < cfg.scan.cache_ttl then
    callback(cached.results)
    return
  end

  local co = coroutine.create(function(resolve)
    local handle = vim.uv.fs_scandir(path)
    if not handle then
      resolve({})
      return
    end

    local results = {}
    local batch_size = cfg.scan.batch_size
    local current_batch = {}

    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then
        if #current_batch > 0 then
          vim.list_extend(results, current_batch)
        end
        break
      end

      if #cfg.scan.ignore_patterns > 0 then
        local ok = vim.iter(cfg.scan.ignore_patterns):any(function(pattern)
          return name:match(pattern)
        end)
        if ok then
          goto continue
        end
      end

      local is_hidden = name:match('^%.')
      if type == 'directory' and not name:match('/$') then
        name = name .. '/'
      end

      table.insert(current_batch, {
        name = name,
        type = type,
        is_hidden = is_hidden,
      })

      if #current_batch >= batch_size then
        vim.list_extend(results, current_batch)
        current_batch = {}
        coroutine.yield()
      end
      ::continue::
    end

    scan_cache:put(path, {
      timestamp = vim.uv.now(),
      results = results,
    })
    resolve(results)
  end)

  local function handle_error(err)
    vim.schedule(function()
      vim.notify(string.format('Error in scan_dir_async: %s', err), vim.log.levels.ERROR)
      callback({})
    end)
  end

  local ok, err = coroutine.resume(co, callback)
  if not ok then
    handle_error(err)
  end
end

-- async cleanup low frequency from dict
local function cleanup_dict()
  if dict.word_count <= dict.max_words then
    return
  end

  local co = coroutine.create(function()
    local words = {}
    local function collect_words(node, current_word)
      if node.is_end then
        table.insert(words, {
          word = current_word,
          frequency = node.frequency,
        })
      end
      -- yield when collect 100 words
      if #words % 100 == 0 then
        coroutine.yield()
      end
      for char, child in pairs(node.children) do
        collect_words(child, current_word .. char)
      end
    end

    collect_words(dict.trie, '')
    coroutine.yield()

    table.sort(words, function(a, b)
      return a.frequency > b.frequency
    end)
    coroutine.yield()

    local new_trie = Trie.new()
    local new_count = 0

    -- rebuild Trie
    for i = 1, dict.max_words do
      if words[i] then
        Trie.insert(new_trie, words[i].word)
        new_count = new_count + 1
      end
      if i % 100 == 0 then
        coroutine.yield()
      end
    end

    dict.trie = new_trie
    dict.word_count = new_count
  end)

  local function resume()
    local ok = coroutine.resume(co)
    if ok and coroutine.status(co) ~= 'dead' then
      vim.schedule(resume)
    end
  end

  vim.schedule(resume)
end

local update_dict = async.throttle(function(lines)
  local processed = 0
  local batch_size = 1000

  local function process_batch()
    local end_idx = math.min(processed + batch_size, #lines)
    local new_words = 0

    for i = processed + 1, end_idx do
      local line = lines[i]
      for word in line:gmatch('[^%s%.%_]+') do
        if not tonumber(word) and #word >= dict.min_word_length then
          if Trie.insert(dict.trie, word) then -- increase when is new word
            new_words = new_words + 1
          end
        end
      end
    end

    dict.word_count = dict.word_count + new_words
    processed = end_idx

    if processed < #lines then
      vim.schedule(process_batch)
    elseif dict.word_count > dict.max_words then
      vim.schedule(function()
        cleanup_dict()
      end)
    end
  end

  vim.schedule(process_batch)
end, cfg.scan.throttle_ms)

local function collect_completions(prefix)
  local results = Trie.search_prefix(dict.trie, prefix)
  table.sort(results, function(a, b)
    return a.frequency > b.frequency
  end)

  local now = vim.uv.now()
  return vim.tbl_map(function(node)
    local time_factor = math.max(0, 1 - (now - node.last_used) / (24 * 60 * 60 * 1000))
    local weight = cfg.dict.frequency_weight + cfg.dict.recency_weight * time_factor
    return {
      label = node.word,
      filterText = node.word,
      kind = 1,
      sortText = string.format('%09d', node.frequency * weight),
    }
  end, results)
end

local function find_last_occurrence(str, pattern)
  local reversed_str = string.reverse(str)
  local start_pos, end_pos = string.find(reversed_str, pattern)
  if start_pos then
    return #str - end_pos + 1
  else
    return nil
  end
end

function server.create()
  return function()
    local srv = {}

    function srv.initialize(params, callback)
      local client_id = params.processId
      if params.rootPath and not projects[params.rootPath] then
        projects[params.rootPath] = {}
      end
      client_capabilities[client_id] = params.capabilities
      callback(nil, {
        capabilities = {
          completionProvider = {
            triggerCharacters = { '/' },
            resolveProvider = false,
          },
          textDocumentSync = {
            openClose = true,
            change = 1,
          },
        },
      })
    end

    function srv.completion(params, callback)
      local uri = params.textDocument.uri
      local position = params.position
      local filename = uri:gsub('file://', '')
      local root = get_root(filename)

      if not root then
        schedule_result(callback)
        return
      end

      local line = root[filename][position.line + 1]
      if not line then
        schedule_result(callback)
        return
      end

      local char_at_cursor = line:sub(position.character, position.character)
      if char_at_cursor == '/' then
        local prefix = line:sub(1, position.character)
        local has_literal = find_last_occurrence(prefix, '"')
        if has_literal then
          prefix = prefix:sub(has_literal + 1, position.character)
        end
        local has_space = find_last_occurrence(prefix, '%s')
        if has_space then
          prefix = prefix:sub(has_space + 1, position.character)
        end
        local dir_part = prefix:match('^(.*/)[^/]*$')

        if not dir_part then
          schedule_result(callback)
          return
        end

        local expanded_path = vim.fs.normalize(vim.fs.abspath(dir_part))

        scan_dir_async(expanded_path, function(results)
          local items = {}
          local current_input = prefix:match('[^/]*$') or ''

          for _, entry in ipairs(results) do
            local name = entry.name
            if vim.startswith(name:lower(), current_input:lower()) then
              local kind = entry.type == 'directory' and 19 or 17
              local label = name
              if entry.type == 'directory' then
                label = label:gsub('/$', '')
              elseif entry.type == 'file' and name:match('^%.') then
                label = label:gsub('^.', '')
              end

              table.insert(items, {
                label = label,
                kind = kind,
                insertText = label,
                filterText = label,
                detail = entry.is_hidden and '(Hidden)' or nil,
                sortText = string.format('%d%s', entry.is_hidden and 1 or 0, label:lower()),
              })
            end
          end

          schedule_result(callback, items)
        end)
      else
        local prefix = line:sub(1, position.character):match('[%w_]*$')
        if not prefix or #prefix == 0 then
          schedule_result(callback)
          return
        end

        local items = collect_completions(prefix)
        schedule_result(callback, items)
      end
    end

    srv['textDocument/completion'] = srv.completion

    srv['textDocument/didOpen'] = function(params)
      local filename = params.textDocument.uri:gsub('file://', '')
      local data = get_root(filename)
      if not data then
        return
      end
      data[filename] = vim.split(params.textDocument.text, '\n')
      update_dict(data[filename])
    end

    srv['textDocument/didChange'] = function(params)
      local filename = params.textDocument.uri:gsub('file://', '')
      local root = get_root(filename)
      if not root then
        return
      end
      root[filename] = vim.split(params.contentChanges[1].text, '\n')
      update_dict(root[filename])

      if dict.word_count > dict.max_words then
        cleanup_dict()
      end
    end

    function srv.shutdown(params, callback)
      callback(nil, nil)
    end

    return {
      request = function(method, params, callback)
        if srv[method] then
          srv[method](params, callback)
        else
          callback('Method not found: ' .. method)
        end
      end,
      notify = function(method, params)
        if srv[method] then
          srv[method](params)
        end
      end,
      is_closing = function()
        return false
      end,
      terminate = function()
        client_capabilities = {}
      end,
    }
  end
end

local function setup()
  vim.api.nvim_create_autocmd('FileType', {
    pattern = cfg.filetypes,
    callback = function()
      vim.lsp.start({
        name = 'phoenix',
        cmd = server.create(),
        root_dir = vim.uv.cwd(),
      })
    end,
  })
end

return { setup = setup }
