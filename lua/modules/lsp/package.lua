packadd({
  'neovim/nvim-lspconfig',
  ft = _G.my_program_ft,
  config = function()
    local i = '■'
    vim.diagnostic.config({ signs = { text = { i, i, i, i } } })
    require('modules.lsp.backend')
    require('modules.lsp.frontend')
  end,
})

packadd({
  'nvimdev/lspsaga.nvim',
  event = 'LspAttach',
  dev = true,
  config = function()
    require('lspsaga').setup({
      symbol_in_winbar = {
        enable = false,
        hide_keyword = true,
        folder_level = 0,
      },
      lightbulb = {
        sign = false,
      },
      outline = {
        layout = 'float',
      },
    })
  end,
})

packadd({
  'nvimdev/epo.nvim',
  event = 'LspAttach',
  config = function()
    require('epo').setup()
  end,
})
