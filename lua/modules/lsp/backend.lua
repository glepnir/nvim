local api, completion, ffi = vim.api, vim.lsp.completion, require('ffi')
local M = {}
local lspconfig = require('lspconfig')

ffi.cdef([[
  typedef int32_t linenr_T
  char *ml_get(linenr_T lnum);
]])

local function has_word_before(triggerCharacters)
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  if col == 0 then
    return false
  end
  local line_text = ffi.string(ffi.C.ml_get(lnum))
  local char_before_cursor = line_text:sub(col, col)
  return char_before_cursor:match('[%w_]')
    or vim.tbl_contains(triggerCharacters, char_before_cursor)
end

function M._attach(client, bufnr)
  api.nvim_create_autocmd({ 'TextChangedI' }, {
    callback = function()
      completion.enable(true, client.id, bufnr)
      local triggerchars =
        vim.tbl_get(client, 'server_capabilities', 'completionProvider', 'triggerCharacters')
      if has_word_before(triggerchars) then
        completion.trigger()
      end
    end,
  })

  vim.opt.omnifunc = 'v:lua.vim.lsp.omnifunc'
  client.server_capabilities.semanticTokensProvider = nil
  local orignal = vim.notify
  local mynotify = function(msg, level, opts)
    if msg == 'No code actions available' or msg:find('overly') then
      return
    end
    orignal(msg, level, opts)
  end
  vim.notify = mynotify
end

lspconfig.gopls.setup({
  cmd = { 'gopls', 'serve' },
  on_attach = M._attach,
  capabilities = M.capabilities,
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
  on_attach = M._attach,
  capabilities = M.capabilities,
  settings = {
    Lua = {
      diagnostics = {
        unusedLocalExclude = { '_*' },
        globals = { 'vim' },
        disable = {
          'luadoc-miss-see-name',
          'undefined-field',
        },
      },
      runtime = {
        version = 'LuaJIT',
        -- path = vim.split(package.path, ';'),
      },
      workspace = {
        library = {
          vim.env.VIMRUNTIME .. '/lua',
          '${3rd}/busted/library',
          '${3rd}/luv/library',
        },
        checkThirdParty = 'Disable',
      },
      completion = {
        callSnippet = 'Replace',
      },
    },
  },
})

lspconfig.clangd.setup({
  cmd = {
    'clangd',
    '--background-index',
  },
  init_options = {
    fallbackFlags = {
      _G.is_mac and '-isystem/Library/Developer/CommandLineTools/SDKs/MacOSX14.4.sdk/usr/include',
      _G.is_mac and '-isystem/opt/homebrew/Cellar/sdl2/2.30.5/include',
      _G.is_mac and '-isystem/opt/homebrew/Cellar/glew/2.2.0_1/include',
      _G.is_mac and '-isystem/opt/homebrew/Cellar/freetype/2.13.2/include/freetype2',
    },
  },
  on_attach = M._attach,
  capabilities = M.capabilities,
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
  on_attach = M._attach,
  capabilities = M.capabilities,
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
}
-- lspconfig.pylsp.setup({ settings = { pylsp = { plugins = { pylint = { enabled = true } } } } })

for _, server in ipairs(servers) do
  lspconfig[server].setup({
    on_attach = M._attach,
    capabilities = M.capabilities,
  })
end

vim.lsp.handlers['workspace/diagnostic/refresh'] = function(_, _, ctx)
  local ns = vim.lsp.diagnostic.get_namespace(ctx.client_id)
  local bufnr = vim.api.nvim_get_current_buf()
  vim.diagnostic.reset(ns, bufnr)
  return true
end

return M
