local client_capabilities = {}
local projects = {}
local dict = {}

--- Custom Server for path and buffer word
--- Usage in ./lua/internal/completion
local server = {}

---@return table
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

---@param path string
---@param callback function
local function scan_dir_async(path, callback)
  local co = coroutine.create(function(resolve)
    local handle = vim.uv.fs_scandir(path)
    if not handle then
      resolve({})
      return
    end

    local results = {}
    while true do
      local name, type = vim.uv.fs_scandir_next(handle)
      if not name then
        break
      end

      local is_hidden = name:match('^%.')
      if type == 'directory' and not name:match('/$') then
        name = name .. '/'
      end

      table.insert(results, {
        name = name,
        type = type,
        is_hidden = is_hidden,
      })
    end

    resolve(results)
  end)

  coroutine.resume(co, callback)
end

---@param path string
---@param callback function
local function check_path_exists_async(path, callback)
  vim.uv.fs_stat(path, function(err, stats)
    callback(not err and stats ~= nil)
  end)
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

local function collect_buffer_words(triggerchar)
  local words = {}
  for _, word in ipairs(dict) do
    -- only compare for alpha
    if word:sub(1, 1) == triggerchar and not vim.list_contains(words, word) then
      table.insert(words, word)
    end
  end
  return vim.tbl_map(function(word)
    return {
      label = word,
      filterText = word,
      kind = 1,
    }
  end, words)
end

local function schedule_result(callback, items)
  vim.schedule(function()
    local mode = vim.api.nvim_get_mode().mode
    if mode == 'i' or mode == 'ic' then
      callback(nil, {
        isIncomplete = #items == 0 and true or false,
        items = items,
      })
    end
  end)
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
            change = 1, -- Full
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
        schedule_result(callback, {})
        return
      end

      local line = root[filename][position.line + 1]
      if not line then
        schedule_result(callback, {})
        return
      end

      local triggerchar = line:sub(position.character, position.character)
      if #triggerchar > 0 and triggerchar ~= '/' and not triggerchar:find('%w') then
        schedule_result(callback, {})
        return
      end

      if triggerchar ~= '/' then
        local items = collect_buffer_words(triggerchar)
        schedule_result(callback, items)
        return
      end

      local prefix = line:sub(1, position.character)
      local has_literal = find_last_occurrence(prefix, '"')
      if has_literal then
        prefix = prefix:sub(has_literal + 1, position.character)
      end
      local has_space = find_last_occurrence(prefix, ' ')
      if has_space then
        prefix = prefix:sub(has_space + 1, position.character)
      end
      local dir_part = prefix:match('^(.*/)[^/]*$')

      if not dir_part then
        callback(nil, { items = {} })
        return
      end

      local expanded_path = vim.fs.normalize(dir_part)

      check_path_exists_async(expanded_path, function(exists)
        if not exists then
          schedule_result(callback, {})
          return
        end

        scan_dir_async(expanded_path, function(results)
          local items = {}
          local current_input = prefix:match('[^/]*$') or ''

          for _, entry in ipairs(results) do
            local name = entry.name
            if vim.startswith(name:lower(), current_input:lower()) then
              local kind = entry.type == 'directory' and 19 or 17 -- 19 for folder, 17 for file
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
      end)
    end

    srv['textDocument/completion'] = srv.completion

    srv['textDocument/didOpen'] = function(params)
      local filename = params.textDocument.uri:gsub('file://', '')
      local data = get_root(filename)
      if not data then
        return
      end
      data[filename] = vim.split(params.textDocument.text, '\n')
    end

    srv['textDocument/didChange'] = function(params)
      local filename = params.textDocument.uri:gsub('file://', '')
      local root = get_root(filename)
      if not root then
        return
      end
      root[filename] = vim.split(params.contentChanges[1].text, '\n')
      for _, line in ipairs(root[filename]) do
        local item = vim.split(line, '%s', { trimempty = true })
        for _, word in ipairs(item) do
          -- no need store number in cache
          if tonumber(word) == nil and not vim.list_contains(dict, word) then
            table.insert(dict, word)
          end
        end
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

return server
