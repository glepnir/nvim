local package = require('core.pack').package
local conf = require('modules.editor.config')

package({
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  config = conf.telescope,
  requires = {
    { 'nvim-lua/plenary.nvim', opt = true },
    { 'nvim-telescope/telescope-fzy-native.nvim', opt = true },
    { 'nvim-telescope/telescope-file-browser.nvim', opt = true },
  },
})

package({
  'nvim-treesitter/nvim-treesitter',
  event = 'BufRead',
  run = ':TSUpdate',
  after = 'telescope.nvim',
  config = conf.nvim_treesitter,
})

package({ 'nvim-treesitter/nvim-treesitter-textobjects', after = 'nvim-treesitter' })

package({ 'glepnir/mcc.nvim', ft = { 'c', 'cpp', 'go', 'rust' }, config = conf.mcc_nvim })

package({
  'glepnir/hlsearch.nvim',
  event = 'BufRead',
  config = function()
    require('hlsearch').setup()
  end,
})

package({ 'phaazon/hop.nvim', event = 'BufRead', config = conf.hop })
