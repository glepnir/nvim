local conf = require('modules.ui.config')

packadd({
  'glepnir/dashboard-nvim',
  dev = true,
  event = 'VimEnter',
  config = conf.dashboard,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

packadd({
  'glepnir/whiskyline.nvim',
  dev = true,
  config = conf.whisky,
  dependencies = { 'nvim-tree/nvim-web-devicons' },
})

packadd({
  'glepnir/gitsigns.nvim',
  dev = true,
  event = { 'BufRead', 'BufNewFile' },
  config = conf.gitsigns,
})
