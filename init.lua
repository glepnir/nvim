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
  'markdown',
  'text',
  'help',
  'css',
}
_G.is_mac = vim.uv.os_uname().sysname == 'Darwin'

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
g.loaded_rrhelper = 1
g.loaded_netrwPlugin = 1
g.loaded_matchparen = 1

local opt = vim.opt
opt.hidden = true
opt.magic = true
opt.virtualedit = 'block'
opt.clipboard = 'unnamedplus'
opt.wildignorecase = true
opt.swapfile = false

opt.timeout = true
opt.ttimeout = true
opt.timeoutlen = 500
opt.ttimeoutlen = 10
opt.updatetime = 100
opt.ignorecase = true
opt.smartcase = true
opt.cursorline = true

opt.showmode = false
opt.shortmess = 'aoOTIcF'
opt.scrolloff = 2
opt.sidescrolloff = 5
opt.ruler = false
opt.showtabline = 0
opt.pumheight = 15
opt.showcmd = false

-- opt.laststatus = 3
opt.list = true

--eol:¬
opt.listchars = 'tab:» ,nbsp:+,trail:·,extends:→,precedes:←,'
opt.undofile = true
opt.linebreak = true

opt.smarttab = true
opt.expandtab = true
opt.autoindent = true
opt.tabstop = 2
opt.sw = 2
opt.foldlevelstart = 99

opt.wrap = false
opt.number = true
opt.signcolumn = 'yes'

opt.textwidth = 80
opt.colorcolumn = '+0'

vim.cmd.colorscheme('solarized')

require('internal.completion')
