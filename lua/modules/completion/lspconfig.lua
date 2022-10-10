local api, lsp = vim.api, vim.lsp
local lspconfig = require('lspconfig')

local capabilities = vim.lsp.protocol.make_client_capabilities()

if not packer_plugins['cmp-nvim-lsp'].loaded then
  vim.cmd([[packadd cmp-nvim-lsp]])
end
capabilities = require('cmp_nvim_lsp').update_capabilities(capabilities)

local signs = {
  Error = ' ',
  Warn = ' ',
  Info = ' ',
  Hint = ' ',
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
    prefix = '🔥',
    source = true,
  },
})

local format_tool_confs = {
  '.stylua.toml',
}

local use_format_tool = function(dir)
  for _, conf in pairs(format_tool_confs) do
    if vim.fn.filereadable(dir .. '/' .. conf) == 1 then
      return true
    end
  end
  return false
end

local on_attach = function(client, bufnr)
  if client.server_capabilities.documentFormattingProvider then
    api.nvim_create_autocmd('BufWritePre', {
      buffer = bufnr,
      callback = function()
        local current_path = vim.fn.expand('%:p')
        if current_path:find('Workspace/neovim') or current_path:find('lspconfig') then
          return
        end

        if vim.bo.filetype == 'go' then
          lsp.buf.code_action({ context = { only = { 'source.organizeImports' } }, apply = true })
        end

        local root_dir = client.config.root_dir
        if root_dir and use_format_tool(root_dir) then
          return
        end
        vim.lsp.buf.format()
      end,
    })
  end
end

lspconfig.gopls.setup({
  on_attach = on_attach,
  cmd = { 'gopls', '--remote=auto' },
  capabilities = capabilities,
  init_options = {
    usePlaceholders = true,
    completeUnimported = true,
  },
})

lspconfig.sumneko_lua.setup({
  on_attach = on_attach,
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

lspconfig.clangd.setup({
  on_attach = on_attach,
  cmd = {
    'clangd',
    '--background-index',
    '--suggest-missing-includes',
    '--clang-tidy',
    '--header-insertion=iwyu',
  },
})

lspconfig.rust_analyzer.setup({
  on_attach = on_attach,
  capabilities = capabilities,
  settings = {
    imports = {
      granularity = {
        group = 'module',
      },
      prefix = 'self',
    },
    cargo = {
      buildScripts = {
        enable = true,
      },
    },
    procMacro = {
      enable = true,
    },
  },
})

local servers = {
  'dockerls',
  'pyright',
  'bashls',
  'zls',
}

lspconfig.tsserver.setup({
  on_attach = on_attach,
})

for _, server in ipairs(servers) do
  lspconfig[server].setup({
    on_attach = on_attach,
  })
end
