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
  dev = true,
  ft = { 'c', 'cpp', 'rust', 'lua', 'go', 'typescript', 'javascript', 'javascriptreact' },
  config = conf.guard,
})

packadd({
  'norcalli/nvim-colorizer.lua',
  ft = { 'lua', 'css', 'html', 'sass', 'less', 'typescriptreact', 'conf', 'vim' },
  config = function()
    require('colorizer').setup()
    exec_filetype('ColorizerSetup')
  end,
})

packadd({
  'nvimdev/dyninput.nvim',
  dev = true,
  ft = { 'c', 'cpp', 'go', 'rust', 'lua' },
  config = conf.dyninput,
})

packadd({
  'nvimdev/hlsearch.nvim',
  event = 'BufRead',
  config = true,
})

packadd({
  'nvimdev/dbsession.nvim',
  dev = true,
  cmd = { 'SessionSave', 'SessionLoad', 'SessionDelete' },
  opts = true,
})

packadd({
  'nvimdev/rapid.nvim',
  dev = true,
  command = 'Rapid',
  config = function()
    require('rapid').setup()
  end,
})
