local conf = require('modules.editor.config')

packadd({
  'L3MON4D3/LuaSnip',
  event = 'InsertCharPre',
  config = conf.lua_snip,
})

packadd({
  'cohama/lexima.vim',
  event = 'InsertEnter',
})

packadd({
  'nvim-telescope/telescope.nvim',
  cmd = 'Telescope',
  config = conf.telescope,
  dependencies = {
    'nvim-lua/plenary.nvim',
    'nvim-telescope/telescope-fzy-native.nvim',
  },
})

packadd({
  'nvim-treesitter/nvim-treesitter',
  event = 'BufRead',
  build = ':TSUpdate',
  config = conf.nvim_treesitter,
  -- disable it until https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/507
  -- solved
  dependencies = {
    'nvim-treesitter/nvim-treesitter-textobjects',
  },
})
