local conf = require('modules.tools.config')

packadd({
  'nvimdev/template.nvim',
  dev = true,
  cmd = 'Template',
  config = conf.template_nvim,
})

packadd({
  'nvimdev/guard.nvim',
  ft = program_ft,
  config = conf.guard,
  dependencies = {
    { 'nvimdev/guard-collection' },
  },
})

packadd({
  'norcalli/nvim-colorizer.lua',
  ft = 'lua',
  config = function()
    vim.opt.termguicolors = true
    require('colorizer').setup()
  end,
})

packadd({
  'nvimdev/dbsession.nvim',
  cmd = { 'SessionSave', 'SessionLoad', 'SessionDelete' },
  opts = true,
})
