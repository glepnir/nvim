local saga = {}

function saga.init_lsp_saga()
  local diagnostic = require 'lspsaga.diagnostic'
  local handlers = require 'lspsaga.handlers'
  local syntax = require 'lspsaga.syntax'

  handlers.overwrite_default()
  diagnostic.lsp_diagnostic_sign()
  syntax.add_highlight()
end

return saga
