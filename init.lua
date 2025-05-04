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

local o = vim.o
o.hidden = true
o.magic = true
o.virtualedit = 'block'
o.clipboard = 'unnamedplus'
o.wildignorecase = true
o.swapfile = false

o.timeout = true
o.ttimeout = true
o.timeoutlen = 500
o.ttimeoutlen = 10
o.updatetime = 100
o.ignorecase = true
o.smartcase = true
o.cursorline = true

o.showmode = false
o.shortmess = 'aoOTIcF'
o.scrolloff = 2
o.sidescrolloff = 5
o.ruler = false
o.showtabline = 0
o.pumheight = 15
o.showcmd = false

-- o.laststatus = 3
o.list = true

--eol:¬
o.listchars = 'tab:» ,nbsp:+,trail:·,extends:→,precedes:←,'
-- o.undofile = true
o.linebreak = true
o.smoothscroll = true

o.smarttab = true
o.expandtab = true
o.autoindent = true
o.tabstop = 2
o.sw = 2
o.foldlevelstart = 99

o.wrap = false
o.number = true
o.signcolumn = 'yes'

o.textwidth = 80
o.colorcolumn = '+0'
o.winborder = 'rounded'

o.cot = 'menu,menuone,noinsert,fuzzy,popup'
o.cia = 'kind,abbr,menu'

vim.cmd.colorscheme('solarized')
