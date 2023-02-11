local package = require('core.pack').package
local conf = require('modules.editor.config')

package({
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  config = conf.telescope,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-fzy-native.nvim',
    'nvim-telescope/telescope-file-browser.nvim',
  },
})

package({
  'nvim-treesitter/nvim-treesitter',
  event = 'BufRead',
  run = ':TSUpdate',
  config = conf.nvim_treesitter,
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
})

package({
  'glepnir/mutchar.nvim',
  dev = true,
  ft = { 'c', 'cpp', 'go', 'rust', 'lua' },
  config = conf.mut_char,
})

package({
  'glepnir/hlsearch.nvim',
  event = 'BufRead',
  config = true,
})

package({
  'glepnir/dbsession.nvim',
  cmd = {'SessionSave', 'SessionLoad', 'SessionDelete'},
  opts = true
})

package({ 'phaazon/hop.nvim', event = 'BufRead', config = conf.hop })
