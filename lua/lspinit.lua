require 'global'
require 'lspconf'
local vim = vim

-- A table to store our root_dir to client_id lookup. We want one LSP per
-- root directory, and this is how we assert that.
local lsp_cache_store = {}

local function lookup_section(settings, section)
  for part in vim.gsplit(section, '.', true) do
    settings = settings[part]
    if not settings then
      return
    end
  end
  return settings
end

local function add_hook_after(func, new_fn)
  if func then
    return function(...)
      -- TODO which result?
      func(...)
      return new_fn(...)
    end
  else
    return new_fn
  end
end

local function add_options(server_setup)
  local options = {
    callbacks = {};
    capabilities = vim.lsp.protocol.make_client_capabilities();
    settings = vim.empty_dict();
    init_options = vim.empty_dict();
  };

  for option,value in pairs(options) do
    if not has_key(server_setup,option) then
      server_setup[option] = value
    end
  end

  server_setup.capabilities = vim.tbl_deep_extend('keep', server_setup.capabilities, {
    workspace = {
      configuration = true;
    }
  })

  -- add workspace/configuration callback function
  server_setup.callbacks["workspace/configuration"] = function(err, method, params, client_id)
      if err then error(tostring(err)) end
      if not params.items then
        return {}
      end

      local result = {}
      for _, item in ipairs(params.items) do
        if item.section then
          local value = lookup_section(server_setup.settings, item.section) or vim.NIL
          -- For empty sections with no explicit '' key, return settings as is
          if value == vim.NIL and item.section == '' then
            value = server_setup.settings or vim.NIL
          end
          table.insert(result, value)
        end
      end
      return result
    end

  server_setup.on_init = add_hook_after(server_setup.on_init, function(client, _result)
        function client.workspace_did_change_configuration(settings)
          if not settings then return end
          if vim.tbl_isempty(settings) then
            settings = {[vim.type_idx]=vim.types.dictionary}
          end
          return client.notify('workspace/didChangeConfiguration', {
            settings = settings;
          })
        end
        if not vim.tbl_isempty(server_setup.settings) then
          client.workspace_did_change_configuration(server_setup.settings)
        end
      end)

  server_setup._on_attach = server_setup.on_attach;

  return server_setup
end

-- Some path manipulation utilities
local function is_dir(filename)
  local stat = vim.loop.fs_stat(filename)
  return stat and stat.type == 'directory' or false
end

-- Asumes filepath is a file.
local function dirname(filepath)
  local is_changed = false
  local result = filepath:gsub(path_sep.."([^"..path_sep.."]+)$", function()
    is_changed = true
    return ""
  end)
  return result, is_changed
end

local function path_join(...)
  return table.concat(vim.tbl_flatten {...}, path_sep)
end

-- Ascend the buffer's path until we find the rootdir.
-- is_root_path is a function which returns bool
local function buffer_find_root_dir(bufnr, is_root_path)
  local bufname = vim.api.nvim_buf_get_name(bufnr)
  if vim.fn.filereadable(bufname) == 0 then
    return nil
  end
  local dir = bufname
  -- Just in case our algo is buggy, don't infinite loop.
  for _ = 1, 100 do
    local did_change
    dir, did_change = dirname(dir)
    if is_root_path(dir, bufname) then
      return dir, bufname
    end
    -- If we can't ascend further, then stop looking.
    if not did_change then
      return nil
    end
  end
end

-- lsp sign
function lsp_sign()
  vim.fn.sign_define('LspDiagnosticsErrorSign', {text='', texthl='LspDiagnosticsError',linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsWarningSign', {text='', texthl='LspDiagnosticsWarning', linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsInformationSign', {text='', texthl='LspDiagnosticsInformation', linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsHintSign', {text='', texthl='LspDiagnosticsHint', linehl='', numhl=''})
end

-- async load completion-nvm then initialize lsp server
function start_lsp_server()
  -- load custom sign
  lsp_sign()

  local client_id = nil
  local bufnr = vim.api.nvim_get_current_buf()
  local buf_filetype = vim.api.nvim_buf_get_option(bufnr,'filetype')
  -- Filter which files we are considering.
  if not has_key(server,buf_filetype) then
    return
  end

  -- Try to find our root directory.
  local root_dir = buffer_find_root_dir(bufnr, function(dir)
    for _,root_file in pairs(server[buf_filetype].root_patterns) do
      if vim.fn.filereadable(path_join(dir, root_file)) == 1 then
        return true
      elseif is_dir(path_join(dir, root_file)) then
        return true
      end
    end
  end)

  -- We couldn't find a root directory, so ignore this file.
  if not root_dir then
    print(string.format("initialize %s failed doesn't find root_dir",server[buf_filetype].name))
    return
  end

  if lsp_cache_store[root_dir] ~= nil then
    client_id = lsp_cache_store[root_dir]
    vim.lsp.buf_attach_client(bufnr, client_id)
    return
  end

  -- async load completion
  local timer = vim.loop.new_timer()
  timer:start(50,0,vim.schedule_wrap(function()
    local loaded,completion = pcall(require,'completion')
    if loaded then
      local on_attach = function(bufnr,client)
        completion.on_attach(bufnr,client)
      end
      server[buf_filetype].on_attach= on_attach
      local new_config = vim.tbl_extend("error",add_options(server[buf_filetype]), {
        root_dir = root_dir;
      })
      client_id = vim.lsp.start_client(new_config)
      lsp_cache_store[root_dir] = client_id
      vim.lsp.buf_attach_client(bufnr, client_id)
      require 'completion'.on_InsertEnter()
      timer:stop()
      timer:close()
      return
    end
  end))
end

start_lsp_server()

function register_lsp_event()
  vim.api.nvim_command [[autocmd InsertEnter * lua start_lsp_server()]]
end

