local conf = require('modules.tools.config')

packadd({
  'glepnir/flybuf.nvim',
  dev = true,
  cmd = 'FlyBuf',
  config = function()
    require('flybuf').setup({})
  end,
})

packadd({ 'glepnir/coman.nvim', dev = true, event = 'BufRead' })

packadd({
  'glepnir/template.nvim',
  dev = true,
  ft = { 'c', 'cpp', 'rust', 'lua', 'go' },
  config = conf.template_nvim,
})

packadd({
  'glepnir/easyformat.nvim',
  dev = true,
  ft = { 'c', 'cpp', 'rust', 'lua', 'go', 'typescript', 'javascrip', 'javascriptreact' },
  config = conf.easyformat,
})

packadd({
  'norcalli/nvim-colorizer.lua',
  ft = { 'lua', 'css', 'html', 'sass', 'less', 'typescriptreact', 'conf' },
  config = function()
    require('colorizer').setup()
  end,
})

packadd({
  'glepnir/mutchar.nvim',
  dev = true,
  ft = { 'c', 'cpp', 'go', 'rust', 'lua' },
  config = conf.mut_char,
})

packadd({
  'glepnir/hlsearch.nvim',
  event = 'BufRead',
  config = true,
})

packadd({
  'glepnir/dbsession.nvim',
  dev = true,
  cmd = { 'SessionSave', 'SessionLoad', 'SessionDelete' },
  opts = true,
})

packadd({ 'phaazon/hop.nvim', event = 'BufRead', config = conf.hop })

packadd({
  'glepnir/nerdicons.nvim',
  dev = true,
  cmd = 'NerdIcons',
  opts = true,
})
