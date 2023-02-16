local package = require('core.pack').package
local conf = require('modules.editor.config')

local enable_lsp_filetype = {
  'go',
  'lua',
  'sh',
  'rust',
  'c',
  'cpp',
  'zig',
  'typescript',
  'typescriptreact',
  'json',
  'python',
  'elixir',
}

package({
  'neovim/nvim-lspconfig',
  dev = true,
  ft = enable_lsp_filetype,
  config = function()
    require('modules.editor.lspconfig')
  end,
})

package({
  'glepnir/lspsaga.nvim',
  ft = enable_lsp_filetype,
  dev = true,
  config = conf.lspsaga,
})

package({
  'L3MON4D3/LuaSnip',
  event = 'InsertCharPre',
  config = conf.lua_snip,
})

package({
  'windwp/nvim-autopairs',
  event = 'InsertEnter',
  config = conf.auto_pairs,
})

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
  'ii14/emmylua-nvim',
  ft = 'lua',
})
