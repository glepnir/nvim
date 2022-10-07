local opt = vim.opt
local cache_dir = os.getenv('HOME') .. '/.cache/nvim/'

opt.termguicolors = true
opt.mouse = 'nv'
opt.hidden = true
opt.fileformats = 'unix,mac,dos'
opt.magic = true
opt.virtualedit = 'block'
opt.clipboard = 'unnamedplus'
opt.wildignorecase = true
opt.wildignore =
  '.git,.hg,.svn,*.pyc,*.o,*.out,*.jpg,*.jpeg,*.png,*.gif,*.zip,**/tmp/**,*.DS_Store,**/node_modules/**,**/bower_modules/**'
opt.backup = false
opt.writebackup = false
opt.swapfile = false
opt.directory = cache_dir .. 'swag/'
opt.undodir = cache_dir .. 'undo/'
opt.backupdir = cache_dir .. 'backup/'
opt.viewdir = cache_dir .. 'view/'
opt.spellfile = cache_dir .. 'spell/en.uft-8.add'
opt.history = 2000
opt.backupskip = '/tmp/*,$TMPDIR/*,$TMP/*,$TEMP/*,*/shm/*,/private/var/*,.vault.vim'
opt.smarttab = true
opt.shiftround = true
opt.timeout = true
opt.ttimeout = true
opt.timeoutlen = 500
opt.ttimeoutlen = 10
opt.updatetime = 100
opt.redrawtime = 1500
opt.ignorecase = true
opt.smartcase = true
opt.infercase = true
opt.incsearch = true
opt.wrapscan = true
opt.grepprg = 'rg --hidden --vimgrep --smart-case --'
opt.whichwrap = 'h,l,<,>,[,],~'
opt.switchbuf = 'useopen'
opt.diffopt = 'filler,iwhite,internal,algorithm:patience'
opt.completeopt = 'menu,menuone,noselect'
opt.jumpoptions = 'stack'
opt.showmode = false
opt.shortmess = 'aoOTIcF'
opt.scrolloff = 2
opt.sidescrolloff = 5
opt.foldlevelstart = 99
opt.ruler = false
opt.list = true
opt.showtabline = 0

opt.pumheight = 15
opt.helpheight = 12
opt.showcmd = false
opt.equalalways = false

opt.cmdheight = 0
opt.laststatus = 3

--wrap
opt.showbreak = '↳  '
opt.breakat = [[\ \	;:,!?]]
opt.breakindentopt = 'shift:2,min:20'

opt.listchars = 'tab:»·,nbsp:+,trail:·,extends:→,precedes:←'
opt.pumblend = 10
opt.winblend = 10

opt.undofile = true
opt.textwidth = 100
opt.expandtab = true
opt.autoindent = true
opt.tabstop = 2
opt.shiftwidth = 2
opt.softtabstop = -1
opt.wrap = false
opt.linebreak = true
opt.number = true
opt.colorcolumn = '100'
opt.signcolumn = 'yes'
opt.spelloptions = 'camel'
-- opt.conceallevel = 2
-- opt.concealcursor = 'niv'

if vim.loop.os_uname().sysname == 'Darwin' then
  vim.g.clipboard = {
    name = 'macOS-clipboard',
    copy = {
      ['+'] = 'pbcopy',
      ['*'] = 'pbcopy',
    },
    paste = {
      ['+'] = 'pbpaste',
      ['*'] = 'pbpaste',
    },
    cache_enabled = 0,
  }
  vim.g.python_host_prog = '/usr/bin/python'
  vim.g.python3_host_prog = '/usr/local/bin/python3'
end
