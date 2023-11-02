local conf = require('modules.editor.config')

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
})

packadd({
  'nvim-treesitter/nvim-treesitter-textobjects',
  --@see https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/507
  event = 'CursorHold',
  config = function()
    require('nvim-treesitter.configs').setup({
      textobjects = {
        select = {
          enable = true,
          keymaps = {
            ['af'] = '@function.outer',
            ['if'] = '@function.inner',
            ['ac'] = '@class.outer',
            ['ic'] = { query = '@class.inner' },
          },
        },
      },
    })
  end,
})
