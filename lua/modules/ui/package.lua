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
  event = 'User DashboardLoaded',
  config = conf.whisky,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

packadd({
  'lewis6991/gitsigns.nvim',
  event = 'User DashboardLoaded',
  config = conf.gitsigns,
})

packadd({
  'nvimdev/indentmini.nvim',
  event = 'User DashboardLoaded',
  config = function()
    require('indentmini').setup({})
  end,
})
