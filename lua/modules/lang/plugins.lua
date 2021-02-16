local lang = {}
local conf = require('modules.lang.config')

lang['ziglang/zig.vim'] = {
  ft = { 'zig','zir' }
}

lang['nvim-treesitter/nvim-treesitter'] = {
  event = 'BufRead *',
  after = 'telescope.nvim',
  config = conf.nvim_treesitter,
}

lang['nvim-treesitter/nvim-treesitter-textobjects'] = {
  after = 'nvim-treesitter'
}

return lang
