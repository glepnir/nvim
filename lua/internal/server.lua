local server = {}

local client_capabilities = {}

local projects = {}

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
        return nil
      end
      local line = root[filename][position.line + 1]
      local prefix = line:sub(1, position.character)

      -- handle path completion
      local last_slash = prefix:match('.*(/[^/]*)$')
      if last_slash == '/' then
        local dir_part = prefix:match('^(.*/)[^/]*$') or './'
        local results = vim.fn.getcompletion(dir_part, 'file', true)

        if next(results) == nil then
          callback(nil, { items = {} })
          return
        end

        local items = {}
        for _, path in ipairs(results) do
          local label = path:gsub(dir_part, ''):gsub('/', '')
          table.insert(items, {
            label = label,
            kind = 17,
            textEdit = {
              range = {
                start = { line = position.line, character = position.character },
                ['end'] = { line = position.line, character = position.character },
              },
              newText = label,
            },
          })
        end

        callback(nil, {
          isIncomplete = false,
          items = items,
        })
      end
    end

    srv['textDocument/completion'] = srv.completion

    srv['textDocument/didOpen'] = function(params)
      local filename = params.textDocument.uri:gsub('file://', '')
      local data
      for r, item in pairs(projects) do
        if vim.startswith(filename, r) then
          data = item
          break
        end
      end
      if not data then
        return
      end
      data[filename] = vim.split(params.textDocument.text, '\n')
    end

    srv['textDocument/didChange'] = function(params)
      local filename = params.textDocument.uri:gsub('file://', '')
      local root = get_root(filename)
      if root then
        root[filename] = vim.split(params.contentChanges[1].text, '\n')
      end
    end

    function srv.shutdown(params, callback)
      callback(nil, nil)
    end

    -- create rpc object
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
