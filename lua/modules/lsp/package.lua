local package = require('core.pack').package

local function lsp_fts(type)
  type = type or nil
  local fts = {}
  fts.backend = {
    'go',
    'lua',
    'sh',
    'rust',
    'c',
    'cpp',
    'zig',
    'python',
  }

  fts.frontend = {
    'javascript',
    'javascriptreact',
    'typescript',
    'typescriptreact',
    'json',
  }
  if not type then
    return vim.list_extend(fts.backend, fts.frontend)
  end
  return fts[type]
end

local loaded = false
local function diag_config()
  local signs = {
    Error = ' ',
    Warn = ' ',
    Info = ' ',
    Hint = ' ',
  }
  for type, icon in pairs(signs) do
    local hl = 'DiagnosticSign' .. type
    vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
  end

  vim.diagnostic.config({
    signs = true,
    severity_sort = true,
    virtual_text = {
      prefix = '🔥',
      source = true,
    },
  })
end

package({
  'neovim/nvim-lspconfig',
  dev = true,
  ft = lsp_fts(),
  config = function()
    if not loaded then
      diag_config()
      loaded = true
    end
    require('modules.lsp.backend')

    -- only load frontend when I write frontend project
    vim.api.nvim_create_autocmd('FileType', {
      patterns = lsp_fts('frontend'),
      callback = function()
        if not package.loaded['modules.lsp.frontend'] then
          require('modules.lsp.frontend')
        end
      end,
      desc = 'Load frontend servers by filetype',
    })
  end,
})

package({
  'glepnir/lspsaga.nvim',
  event = 'LspAttach',
  cmd = 'Lspsaga term_toggle',
  dev = true,
  config = function()
    require('lspsaga').setup({
      symbol_in_winbar = {
        ignore_patterns = { '%w_spec' },
      },
    })
  end,
})
