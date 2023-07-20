local conf = require('modules.ui.config')

packadd({
  'nvimdev/paradox.vim',
  dev = true,
  config = function()
    vim.cmd('colorscheme paradox')
  end,
})

packadd({
  'nvimdev/dashboard-nvim',
  event = 'VimEnter',
  config = conf.dashboard,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

packadd({
  'nvimdev/whiskyline.nvim',
  dev = true,
  config = conf.whisky,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

packadd({
  'lewis6991/gitsigns.nvim',
  event = { 'BufRead', 'BufNewFile' },
  config = conf.gitsigns,
})

packadd({
  'nvimdev/indentmini.nvim',
  event = { 'BufEnter' },
  dev = true,
  config = function()
    require('indentmini').setup({})
  end,
})
