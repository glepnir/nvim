local vim,api,lsp = vim,vim.api,vim.lsp
local callbacks = {}

local function lookup_section(settings, section)
  for part in vim.gsplit(section, '.', true) do
    settings = settings[part]
    if not settings then
      return
    end
  end
  return settings
end

--@private
local function ok_or_nil(status, ...)
  if not status then return end
  return ...
end
--@private
local function npcall(fn, ...)
  return ok_or_nil(pcall(fn, ...))
end
--@private
local function find_window_by_var(name, value)
  for _, win in ipairs(api.nvim_list_wins()) do
    if npcall(api.nvim_win_get_var, win, name) == value then
      return win
    end
  end
end

local function focusable_float(unique_name, fn)
  -- Go back to previous window if we are in a focusable one
  if npcall(api.nvim_win_get_var, 0, unique_name) then
    return api.nvim_command("wincmd p")
  end
  local bufnr = api.nvim_get_current_buf()
  do
    local win = find_window_by_var(unique_name, bufnr)
    print(win)
    if win and api.nvim_win_is_valid(win) and not vim.fn.pumvisible() then
      api.nvim_set_current_win(win)
      api.nvim_command("stopinsert")
      return
    end
  end
  local pbufnr, pwinnr = fn()
  if pbufnr then
    api.nvim_win_set_var(pwinnr, unique_name, bufnr)
    return pbufnr, pwinnr
  end
end

local function focusable_preview(unique_name, fn)
  return focusable_float(unique_name, function()
    return vim.lsp.util.open_floating_preview(fn())
  end)
end

local function signature_help_callback(_,method,result)
  if not (result and result.signatures and result.signatures[1]) then
    return
  end
  local lines = lsp.util.convert_signature_help_to_markdown_lines(result)
  lines = lsp.util.trim_empty_lines(lines)
  if vim.tbl_isempty(lines) then
    return
  end
  focusable_preview(method, function()
    return lines, lsp.util.try_trim_markdown_code_blocks(lines)
  end)
end

-- Add I custom callbacks function in lsp server config
function callbacks.add_callbacks(server_setup)

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
  server_setup.callbacks["workspace/configuration"] = function(err, _, params, _)
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
    api.nvim_command("doautocmd User LspDiagnosticsChanged")
  end
  server_setup.callbacks["textDocument/signatureHelp"] = signature_help_callback
end

function callbacks.show_signature_help()
  local params = vim.lsp.util.make_position_params()
  return vim.lsp.buf_request(0,'textDocument/signatureHelp',params,signature_help_callback)
end

return callbacks
