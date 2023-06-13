local lspconfig = require('lspconfig')
local _attach = require('modules.lsp.backend')._attach

lspconfig.jsonls.setup({
  on_attach = _attach,
})

-- npm i -g typescript
-- npm i -g typescript-langauge-server
lspconfig.tsserver.setup({
  on_attach = _attach,
})

-- npm i -g vscode-langservers-extracted
lspconfig.eslint.setup({
  filetypes = { 'javascriptreact', 'typescriptreact' },
  on_attach = function(client, bufnr)
    _attach(client)
    vim.api.nvim_create_autocmd('BufWritePre', {
      buffer = bufnr,
      command = 'EslintFixAll',
    })
  end,
})
