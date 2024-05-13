local conf = require('modules.tools.config')

packadd({
  'nvimdev/flybuf.nvim',
  cmd = 'FlyBuf',
  config = function()
    require('flybuf').setup({})
  end,
})

packadd({
  'nvimdev/template.nvim',
  dev = true,
  cmd = 'Template',
  config = conf.template_nvim,
})

packadd({
  'nvimdev/guard.nvim',
  ft = { 'c', 'cpp', 'rust', 'lua', 'go', 'typescript', 'javascript', 'javascriptreact' },
  config = conf.guard,
  dependencies = {
    { 'nvimdev/guard-collection' },
  },
})

packadd({
  'norcalli/nvim-colorizer.lua',
  ft = { 'css', 'html', 'sass', 'less', 'typescriptreact', 'conf', 'vim' },
  config = function()
    vim.opt.termguicolors = true
    require('colorizer').setup()
  end,
})

packadd({
  'nvimdev/hlsearch.nvim',
  event = 'BufRead',
  config = true,
})

packadd({
  'nvimdev/dbsession.nvim',
  cmd = { 'SessionSave', 'SessionLoad', 'SessionDelete' },
  opts = true,
})
