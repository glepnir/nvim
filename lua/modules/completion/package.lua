local package = require('core.pack').package
local conf = require('modules.completion.config')

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
  config = conf.nvim_lsp,
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

package({ 'windwp/nvim-autopairs', event = 'InsertEnter', config = conf.auto_pairs })
