local package = require('core.pack').package
local conf = require('modules.lang.config')

package {'nvim-treesitter/nvim-treesitter',
  event = 'BufRead',
  run = ':TSUpdate',
  after = 'telescope.nvim',
  config = conf.nvim_treesitter,
}

package {'nvim-treesitter/nvim-treesitter-textobjects', after = 'nvim-treesitter'}

package {'glepnir/smartinput.nvim', ft = 'go',config = conf.smart_input}
