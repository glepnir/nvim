local g = vim.g
--disable_distribution_plugins
g.loaded_gzip = 1
g.loaded_tar = 1
g.loaded_tarPlugin = 1
g.loaded_zip = 1
g.loaded_zipPlugin = 1
g.loaded_getscript = 1
g.loaded_getscriptPlugin = 1
g.loaded_vimball = 1
g.loaded_vimballPlugin = 1
g.loaded_matchit = 1
g.loaded_matchparen = 1
g.loaded_2html_plugin = 1
g.loaded_logiPat = 1
g.loaded_rrhelper = 1
g.loaded_netrwPlugin = 1
g.mapleader = ' '

-- the programming language which i write.
g.my_program_ft = {
  'go',
  'lua',
  'sh',
  'rust',
  'c',
  'cpp',
  'zig',
  'python',
  'javascript',
  'javascriptreact',
  'typescript',
  'typescriptreact',
  'json',
}

require('core.pack'):boot_strap()
require('core.options')
