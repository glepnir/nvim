local conf = require('modules.ui.config')

packadd({
  'nvimdev/dashboard-nvim',
  event = 'UIEnter',
  config = conf.dashboard,
})

packadd({
  'nvimdev/modeline.nvim',
  event = 'BufEnter */*',
  config = function()
    require('modeline').setup()
  end,
})

packadd({
  'lewis6991/gitsigns.nvim',
  event = 'BufEnter */*',
  config = conf.gitsigns,
})

packadd({
  'nvimdev/indentmini.nvim',
  event = 'BufEnter */*',
  config = function()
    vim.opt_local.listchars:append({ tab = '  ' })
    require('indentmini').setup({
      only_current = true,
    })
  end,
})
