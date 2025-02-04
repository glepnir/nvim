packadd({
  'neovim/nvim-lspconfig',
  ft = program_ft,
  config = function()
    -- vim.lsp.set_log_level(vim.lsp.log_levels.OFF)
    local i = '●'
    vim.diagnostic.config({
      signs = {
        text = { i, i, i, i },
      },
    })
    require('modules.lsp.config')
  end,
})

packadd({
  'nvimdev/phoenix.nvim',
  ft = program_ft,
  dev = true,
})

packadd({
  'nvimdev/lspsaga.nvim',
  event = 'LspAttach',
  dev = true,
  config = function()
    require('lspsaga').setup({
      ui = { use_nerd = false },
      symbol_in_winbar = {
        enable = false,
      },
      lightbulb = {
        enable = false,
      },
      outline = {
        layout = 'float',
      },
    })
  end,
})
