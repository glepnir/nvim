require 'global'

server = {}

-- gopls configuration template
server.gopls_setup = {
  name = "gopls";
  on_attach= require'completion'.on_attach;
  -- A table to store our root_dir to client_id lookup. We want one LSP per
  -- root directory, and this is how we assert that.
  store = {};
  cmd = {"gopls"};
  filetypes = {'go','gomod'};
  root_patterns = {'go.mod','.git'};
  -- https://github.com/golang/tools/blob/master/gopls/doc/settings.md#settings
  -- init_options = vim.empty_dict();
  -- settings = vim.empty_dict();
  -- callbacks = {};
  -- capabilities = vim.lsp.protocol.make_client_capabilities()
}

-- check value in table
local function has_value (tab, val)
  for index, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

-- check index in table
local function has_key (tab,idx)
  for index,value in pairs(tab) do
    if index == idx then
      return true
    end
  end
  return false
end

local function add_config_options(server_setup)
  local options = { 'callbacks','capabilities', 'settings','init_options',}
  for key,value in pairs(options) do
    if not has_key(server_setup,value) then
      if key == options[1] or key == options[3] or key == options[3] then
        server_setup[value] = {}
      else
        server_setup[value] = vim.lsp.protocol.make_client_capabilities()
      end
    end
  end
  print(dump(server_setup))
  return server_setup
end

add_config_options(server.gopls_setup)

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

-- custom lsp sign
function lsp_sign()
  vim.fn.sign_define('LspDiagnosticsErrorSign', {text='', texthl='LspDiagnosticsError',linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsWarningSign', {text='', texthl='LspDiagnosticsWarning', linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsInformationSign', {text='', texthl='LspDiagnosticsInformation', linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsHintSign', {text='', texthl='LspDiagnosticsHint', linehl='', numhl=''})
end

-- This needs to be global so that we can call it from the autocmd.
function start_lsp_server(server_setup)
  local bufnr = vim.api.nvim_get_current_buf()
  -- Filter which files we are considering.
  if not has_value(server_setup.filetypes,vim.api.nvim_buf_get_option(bufnr,'filetype')) then
    print(string.format("initialize %s failed filetype doesn't match",server_setup.name))
    return
  end

  -- Try to find our root directory.
  local root_dir = buffer_find_root_dir(bufnr, function(dir)
    for _,root_file in pairs(server_setup.root_patterns) do
      if vim.fn.filereadable(path_join(dir, root_file)) == 1 then
        return true
      elseif is_dir(path_join(dir, root_file)) then
        return true
      end
    end
  end)

  -- We couldn't find a root directory, so ignore this file.
  if not root_dir then
    print(string.format("initialize %s failed doesn't find root_dir",server_setup.name))
    return
  end

  -- Check if we have a client alredy or start and store it.
  local client_id = server_setup.store[root_dir]
  if not client_id then
    local new_config = vim.tbl_extend("error", server_setup, {
      root_dir = root_dir;
    })
    client_id = vim.lsp.start_client(new_config)
    server_setup.store[root_dir] = client_id
  end
  -- load custom sign
  lsp_sign()
  -- Finally, attach to the buffer to track changes. This will do nothing if we
  -- are already attached.
  vim.lsp.buf_attach_client(bufnr, client_id)
  print(string.format("initialize %s success",server_setup.name))
end

-- start_lsp_server(add_config_options(server.gopls_setup))
start_lsp_server(server.gopls_setup)
