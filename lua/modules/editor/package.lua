local conf = require('modules.editor.config')

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
  event = { 'BufRead', 'BufNewFile' },
  build = ':TSUpdate',
  config = conf.nvim_treesitter,
})

--@see https://github.com/nvim-treesitter/nvim-treesitter-textobjects/issues/507
packadd({
  'nvim-treesitter/nvim-treesitter-textobjects',
  ft = { 'c', 'rust', 'go', 'lua' },
  config = function()
    vim.defer_fn(function()
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
    end, 0)
  end,
})
