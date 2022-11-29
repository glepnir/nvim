local package = require('core.pack').package
local conf = require('modules.ui.config')

package({ '~/Workspace/zephyr-nvim', config = conf.zephyr })

package({ '~/Workspace/dashboard-nvim', config = conf.dashboard })

package({
  'glepnir/galaxyline.nvim',
  config = conf.galaxyline,
  requires = 'kyazdani42/nvim-web-devicons',
})

local enable_indent_filetype = {
  'go',
  'lua',
  'sh',
  'rust',
  'cpp',
  'typescript',
  'typescriptreact',
  'javascript',
  'json',
  'python',
}

package({
  'lukas-reineke/indent-blankline.nvim',
  ft = enable_indent_filetype,
  config = conf.indent_blankline,
})

package({
  'lewis6991/gitsigns.nvim',
  event = { 'BufRead', 'BufNewFile' },
  config = conf.gitsigns,
})
