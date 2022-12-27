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

package({ 'mcc.nvim', dev = true, ft = { 'c', 'cpp', 'go', 'rust' }, config = conf.mcc_nvim })

package({
  'glepnir/hlsearch.nvim',
  event = 'BufRead',
  config = function()
    require('hlsearch').setup()
  end,
})

package({ 'phaazon/hop.nvim', event = 'BufRead', config = conf.hop })
