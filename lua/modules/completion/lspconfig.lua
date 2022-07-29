local home = os.getenv('HOME')
local lspconfig = require('lspconfig')

if not packer_plugins['lspsaga.nvim'].loaded then
  vim.cmd([[packadd lspsaga.nvim]])
end

local saga = require('lspsaga')
saga.init_lsp_saga({
  -- symbols in winbar
  symbol_in_winbar = {
    enable = true,
  },
})

local capabilities = vim.lsp.protocol.make_client_capabilities()

if not packer_plugins['cmp-nvim-lsp'].loaded then
  vim.cmd([[packadd cmp-nvim-lsp]])
end
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

function _G.reload_lsp()
  vim.lsp.stop_client(vim.lsp.get_active_clients())
  vim.cmd([[edit]])
end

function _G.open_lsp_log()
  local path = vim.lsp.get_log_path()
  vim.cmd('edit ' .. path)
end

vim.cmd('command! -nargs=0 LspLog call v:lua.open_lsp_log()')
vim.cmd('command! -nargs=0 LspRestart call v:lua.reload_lsp()')

local signs = {
  Error = ' ',
  Warn = ' ',
  Info = ' ',
  Hint = 'ﴞ ',
}
for type, icon in pairs(signs) do
  local hl = 'DiagnosticSign' .. type
  vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
end

vim.diagnostic.config({
  signs = true,
  update_in_insert = false,
  underline = true,
  severity_sort = true,
  virtual_text = {
    source = true,
  },
})

lspconfig.gopls.setup({
  cmd = { 'gopls', '--remote=auto' },
  capabilities = capabilities,
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
  },
})

lspconfig.sumneko_lua.setup({
  settings = {
    Lua = {
      diagnostics = {
        enable = true,
        globals = { 'vim', 'packer_plugins' },
      },
      runtime = { version = 'LuaJIT' },
      workspace = {
        library = vim.list_extend({ [vim.fn.expand('$VIMRUNTIME/lua')] = true }, {}),
      },
    },
  },
})

lspconfig.tsserver.setup({
  on_attach = function(client)
    client.server_capabilities.document_formatting = false
  end,
})

lspconfig.clangd.setup({
  cmd = {
    'clangd',
    '--background-index',
    '--suggest-missing-includes',
    '--clang-tidy',
    '--header-insertion=iwyu',
  },
})

lspconfig.rust_analyzer.setup({
  capabilities = capabilities,
  settings = {
    ['rust-analyzer'] = {
      assist = {
        importGranularity = 'module',
        importPrefix = 'self',
      },
      cargo = {
        loadOutDirsFromCheck = true,
      },
      procMacro = {
        enable = true,
      },
    },
  },
})

local servers = {
  'volar',
  'cssls',
  'dockerls',
  'pyright',
  'tsserver',
  'bashls',
}

for _, server in ipairs(servers) do
  lspconfig[server].setup({})
end
