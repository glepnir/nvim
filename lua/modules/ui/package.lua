local conf = require('modules.ui.config')

packadd({
  'glepnir/porcelain.nvim',
  dev = true,
  config = function()
    vim.cmd.colorscheme('porcelain')
  end,
})

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
  'lewis6991/gitsigns.nvim',
  dev = true,
  event = { 'BufRead', 'BufNewFile' },
  config = conf.gitsigns,
})
