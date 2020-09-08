local global = require 'global'
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

return callbacks
