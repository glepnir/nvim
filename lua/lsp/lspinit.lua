require 'global'
local server = require 'lsp.lspconf'
local autocmd = require 'event'
local vim,api,lsp = vim,vim.api,vim.lsp

-- A table to store our root_dir to client_id lookup. We want one LSP per
-- root directory, and this is how we assert that.
local lsp_store = {}

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

-- signature help callback function
local signature_help_callback = function(_, _, result)
    if not (result and result.signatures and #result.signatures > 0) then
        return { 'No signature available' }
    end
    local active_signature = result.activeSignature or 0
    if active_signature >= #result.signatures then
        active_signature = 0
    end
    local signature = result.signatures[active_signature + 1]
    if not signature then
        return { 'No signature available' }
    end

    local highlights = {}
    if signature.parameters then
        local active_parameter = result.activeParameter or 0
        if active_parameter >= #signature.parameters then
            active_parameter = 0
        end
        local parameter = signature.parameters[active_parameter + 1]
        if parameter and parameter.label then
            local label_type = type(parameter.label)
            if label_type == "string" then
                local l, r = string.find(signature.label, parameter.label, 1, true)
                if l and r then
                    highlights = {l, r + 1}
                end
            elseif label_type == "table" then
                local l, r = unpack(parameter.label)
                highlights = {l + 1, r + 1}
            end
        end
    end

    local filetype = api.nvim_buf_get_option(0, "filetype")
    if filetype and type(signature.label) == "string" then
        signature.label = string.format("```%s\n%s\n```", filetype, signature.label)
    end

    local lines = lsp.util.convert_signature_help_to_markdown_lines(result)
    lines = lsp.util.trim_empty_lines(lines)
    if vim.tbl_isempty(lines) then
        return { 'No signature available' }
    end
    local bufnr, winnr = lsp.util.fancy_floating_markdown(lines, {
        pad_left = 1, pad_right = 1
    })
    if #highlights > 0 then
        api.nvim_buf_add_highlight(bufnr, -1, 'Underlined', 0, highlights[1], highlights[2])
    end
    lsp.util.close_preview_autocmd({"CursorMoved", "CursorMovedI", "BufHidden", "BufLeave"}, winnr)
end

-- Add I custom callbacks function in lsp server config
local function add_callbacks(server_setup)

  server_setup.callbacks["window/logMessage"] = function(err, method, params, client_id)
        if params and params.type <= server_setup.log_level then
          assert(vim.lsp.callbacks["window/logMessage"], "Callback for window/logMessage notification is not defined")
          vim.lsp.callbacks["window/logMessage"](err, method, params, client_id)
        end
      end

  server_setup.callbacks["window/showMessage"] = function(err, method, params, client_id)
    if params and params.type <= server_setup.message_level then
      assert(vim.lsp.callbacks["window/showMessage"], "Callback for window/showMessage notification is not defined")
      vim.lsp.callbacks["window/showMessage"](err, method, params, client_id)
    end
  end

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

  -- diagnostic callbacks
  server_setup.callbacks['textDocument/publishDiagnostics'] = function(_, _, result)
    if not result then return end
    local uri = result.uri
    local bufnr = vim.uri_to_bufnr(uri)
    if not bufnr then
      vim.api.nvim_out_write(string.format("LSP.publishDiagnostics: Couldn't find buffer for %s", uri))
      return
    end
    lsp.util.buf_clear_diagnostics(bufnr)

    -- https://microsoft.github.io/language-server-protocol/specifications/specification-current/#diagnostic
    -- The diagnostic's severity. Can be omitted. If omitted it is up to the
    -- client to interpret diagnostics as error, warning, info or hint.
    -- TODO: Replace this with server-specific heuristics to infer severity.
    for _, diagnostic in ipairs(result.diagnostics) do
      if diagnostic.severity == nil then
        diagnostic.severity = vim.lsp.protocol.DiagnosticSeverity.Error
      end
    end

    lsp.util.buf_diagnostics_save_positions(bufnr, result.diagnostics)
    lsp.util.buf_diagnostics_underline(bufnr, result.diagnostics)
    if vim.g.lsp_diagnostic_virtual_text == 1 then
      -- use virtual text show message diagnostic
      lsp.util.buf_diagnostics_virtual_text(bufnr, result.diagnostics)
    end
    lsp.util.buf_diagnostics_signs(bufnr, result.diagnostics)
    vim.api.nvim_command("doautocmd User LspDiagnosticsChanged")
  end

  server_setup.callbacks["textDocument/signatureHelp"] = signature_help_callback
end

local function add_options(server_setup)
  local options = {
    callbacks = {};
    capabilities = vim.lsp.protocol.make_client_capabilities();
    settings = vim.empty_dict();
    init_options = vim.empty_dict();
    log_level = vim.lsp.protocol.MessageType.Warning;
    message_level = vim.lsp.protocol.MessageType.Warning;
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

  add_callbacks(server_setup)

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
  local bufname = api.nvim_buf_get_name(bufnr)
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
local function lsp_sign()
  vim.fn.sign_define('LspDiagnosticsErrorSign', {text='', texthl='LspDiagnosticsError',linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsWarningSign', {text='', texthl='LspDiagnosticsWarning', linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsInformationSign', {text='', texthl='LspDiagnosticsInformation', linehl='', numhl=''})
  vim.fn.sign_define('LspDiagnosticsHintSign', {text='', texthl='LspDiagnosticsHint', linehl='', numhl=''})
end

local function load_completion()
  local loaded,completion = pcall(require,'completion')
  if loaded then
    api.nvim_buf_set_var(0, 'completion_enable', 1)
    completion.on_InsertEnter()
    completion.confirmCompletion()
  end
end

-- Synchronously organise (Go) imports. Taken from
-- https://github.com/neovim/nvim-lsp/issues/115#issuecomment-654427197.
function go_organize_imports_sync(timeout_ms)
  local context = { source = { organizeImports = true } }
  vim.validate { context = { context, 't', true } }
  local params = vim.lsp.util.make_range_params()
  params.context = context

  -- See the implementation of the textDocument/codeAction callback
  -- (lua/vim/lsp/callbacks.lua) for how to do this properly.
  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, timeout_ms)
  if not result then return end
  local actions = result[1].result
  if not actions then return end
  local action = actions[1]

  -- textDocument/codeAction can return either Command[] or CodeAction[]. If it
  -- is a CodeAction, it can have either an edit, a command or both. Edits
  -- should be executed first.
  if action.edit or type(action.command) == "table" then
    if action.edit then
      vim.lsp.util.apply_workspace_edit(action.edit)
    end
    if type(action.command) == "table" then
      vim.lsp.buf.execute_command(action.command)
    end
  else
    vim.lsp.buf.execute_command(action)
  end
end

-- async load completion-nvm then initialize lsp server
function lsp_store.start_lsp_server()
  -- load custom sign
  lsp_sign()

  local client_id = nil
  local bufnr = api.nvim_get_current_buf()
  local buf_filetype = api.nvim_buf_get_option(bufnr,'filetype')
  -- Filter which files we are considering.
  if not has_key(server,buf_filetype) then
    -- load completion in buffer for complete something else
    load_completion()
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
    load_completion()
    print(string.format("initialize %s failed doesn't find root_dir",server[buf_filetype].name))
    return
  end

  -- If the current file root dir in cache,we just attach it
  -- also the completion already in runtimepath just to call it
  if lsp_store[root_dir] ~= nil then
    client_id = lsp_store[root_dir]
    vim.lsp.buf_attach_client(bufnr, client_id)
    local loaded,completion = pcall(require,'completion')
    if loaded then
      api.nvim_buf_set_var(0, 'completion_enable', 1)
      completion.on_InsertEnter()
      completion.confirmCompletion()
    end
    return
  end

  -- async load completion
  local timer = vim.loop.new_timer()
  timer:start(50,0,vim.schedule_wrap(function()
    local loaded,completion = pcall(require,'completion')
    if loaded then
      -- When require completion success,We call the on_InsertEnter by ourself.
      -- Must set the completion_enable to 1
      api.nvim_buf_set_var(0, 'completion_enable', 1)
      completion.on_InsertEnter()
      completion.confirmCompletion()

      local on_attach = function(client,bufnr)
        -- define an chain complete list
        local chain_complete_list = {
          default = {
            {complete_items = {'lsp'}},
            {complete_items = {'snippet'}},
            {complete_items = {'path'}, triggered_only = {'/'}},
          }
        }
        -- passing in a table with on_attach function
        completion.on_attach({
            chain_complete_list = chain_complete_list,
          })

        local lsp_event = {}
        if client.resolved_capabilities.document_highlight then
          lsp_event.highlights = {
            {"CursorHold,CursorHoldI","<buffer>", "lua vim.lsp.buf.document_highlight()"};
            {"CursorMoved","<buffer>","lua vim.lsp.buf.clear_references()"};
          }
        end
        if client.resolved_capabilities.document_formatting then
          if vim.api.nvim_buf_get_option(bufnr, "filetype") == "go" then
            lsp_event.organizeImports = {
              {"BufWritePre","<buffer>","lua go_organize_imports_sync(1000)"}
            }
          end
          lsp_event.autoformat = {
            {"BufWritePre","<buffer>","lua vim.lsp.buf.formatting_sync(nil, 1000)"}
          }
        end

        -- register lsp event
        autocmd.nvim_create_augroups(lsp_event)
        -- register lsp diagnostic error jump command
        api.nvim_command("command! -count=1 DiagnosticPrev lua require'lsp.lspdiag'.lsp_jump_diagnostic_prev(<count>)")
        api.nvim_command("command! -count=1 DiagnosticNext lua require'lsp.lspdiag'.lsp_jump_diagnostic_next(<count>)")
        -- use floatwindow to show diagnostc message
        lsp.util.show_line_diagnostics()
        -- Source omnicompletion from LSP.
        vim.api.nvim_buf_set_option(bufnr, "omnifunc", "v:lua.vim.lsp.omnifunc")
      end

      -- config the server config on_attach
      server[buf_filetype].on_attach= on_attach
      -- build a new server config
      local new_config = vim.tbl_extend("error",add_options(server[buf_filetype]), {
        root_dir = root_dir;
      })
      -- start a new lsp server and store the cliend_id
      client_id = vim.lsp.start_client(new_config)
      if client_id ~= nil and timer:is_closing() == false then
        lsp_store[root_dir] = client_id
        vim.lsp.buf_attach_client(bufnr, client_id)
        timer:stop()
        timer:close()
      end
    end
  end))
end

return lsp_store
