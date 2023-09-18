local conf = require('modules.ui.config')

packadd({
  'nvimdev/paradox.vim',
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
  event = 'BufEnter */*',
  config = conf.whisky,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

packadd({
  'lewis6991/gitsigns.nvim',
  event = 'BufEnter */*',
  config = conf.gitsigns,
})

packadd({
  'nvimdev/indentmini.nvim',
  event = 'BufEnter',
  config = function()
    require('indentmini').setup({})
  end,
})
