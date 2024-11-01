local g = vim.g
vim.loader.enable()
g.mapleader = vim.keycode('<space>')
-- the programming language which i write.
_G.program_ft = {
  'c',
  'cpp',
  'rust',
  'zig',
  'go',
  'lua',
  'sh',
  'python',
  'javascript',
  'javascriptreact',
  'typescript',
  'typescriptreact',
  'json',
  'cmake',
  'html',
}
_G.is_mac = vim.uv.os_uname().sysname == 'Darwin'

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
g.loaded_2html_plugin = 1
g.loaded_logiPat = 1
g.loaded_rrhelper = 1
g.loaded_netrwPlugin = 1
g.loaded_matchparen = 1

-- Load Modules
require('core')
require('internal.event')
require('internal.completion')
