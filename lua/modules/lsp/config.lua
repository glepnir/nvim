local lspconfig = require('lspconfig')

vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_clients({ id = args.data.client_id })[1]
    client.server_capabilities.semanticTokensProvider = nil
  end,
})

lspconfig.gopls.setup({
  cmd = { 'gopls', 'serve' },
  settings = {
    gopls = {
      usePlaceholders = true,
      completeUnimported = true,
      analyses = {
        unusedparams = true,
      },
      -- semanticTokens = true,
      staticcheck = true,
    },
  },
})

lspconfig.lua_ls.setup({
  on_init = function(client)
    local path = client.workspace_folders and client.workspace_folders[1].name
    local fs_stat = vim.uv.fs_stat
    if path and (fs_stat(path .. '/.luarc.json') or fs_stat(path .. '/.luarc.jsonc')) then
      return
    end
    client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
      runtime = { version = 'LuaJIT' },
      completion = { callSnippet = 'Replace' },
      workspace = {
        checkThirdParty = false,
        library = {
          vim.env.VIMRUNTIME,
          '${3rd}/luv/library',
        },
      },
    })
  end,
  settings = { Lua = {} },
})

lspconfig.clangd.setup({
  cmd = { 'clangd', '--background-index' },
  init_options = { fallbackFlags = { vim.bo.filetype == 'cpp' and '-std=c++23' or nil } },
  root_dir = function(fname)
    return lspconfig.util.root_pattern(unpack({
      --reorder
      'compile_commands.json',
      '.clangd',
      '.clang-tidy',
      '.clang-format',
      'compile_flags.txt',
      'configure.ac', -- AutoTools
    }))(fname) or lspconfig.util.find_git_ancestor(fname)
  end,
})

lspconfig.rust_analyzer.setup({
  settings = {
    ['rust-analyzer'] = {
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
  },
})

local servers = {
  'pyright',
  'bashls',
  'zls',
  'cmake',
  'jsonls',
  'ts_ls',
  'eslint',
  'ruff',
  -- 'basics_ls',
}

for _, server in ipairs(servers) do
  lspconfig[server].setup({})
end

vim.lsp.handlers['workspace/diagnostic/refresh'] = function(_, _, ctx)
  local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.diagnostic.reset(ns, bufnr)
  return true
end
