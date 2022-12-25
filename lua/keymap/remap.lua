local keymap = require('core.keymap')
local nmap, imap, cmap, tmap = keymap.nmap, keymap.imap, keymap.cmap, keymap.tmap
local expr = keymap.expr
local opts = keymap.new_opts
local cmd = keymap.cmd

-- noremal remap
nmap({
  -- close buffer
  { '<C-x>k', cmd('bdelete') },
  -- save
  { '<C-s>', cmd('write') },
  -- buffer jump
  { ']b', cmd('bn') },
  { '[b', cmd('bp') },
  -- force quit all
  { '<C-q>', cmd('qa!') },
  -- remove trailing white space
  { '<Leader>t', cmd('TrimTrailingWhitespace') },
  -- window jump
  { '<C-h>', '<C-w>h' },
  { '<C-l>', '<C-w>l' },
  { '<C-j>', '<C-w>j' },
  { '<C-k>', '<C-w>k' },
  -- resize window
  { '<A-[>', cmd('vertical resize -5') },
  { '<A-]>', cmd('vertical resize +5') },
})

-- insertmode remap
imap({
  { '<C-w>', '<C-[>diwa' },
  { '<C-h>', '<Bs>' },
  { '<C-d>', '<Del>' },
  { '<C-u>', '<C-G>u<C-u>' },
  { '<C-b>', '<Left>' },
  { '<C-f>', '<Right>' },
  { '<C-n>', '<Down>' },
  { '<C-p>', '<Up>' },
  { '<C-a>', '<Esc>^i' },
  { '<C-j>', '<Esc>o' },
  { '<C-k>', '<Esc>O' },
  { '<C-s>', '<ESC>:w<CR>' },
  {
    '<C-e>',
    function()
      return vim.fn.pumvisible() == 1 and '<C-e>' or '<End>'
    end,
    opts(expr),
  },
})

-- commandline remap
cmap({
  { '<C-b>', '<Left>' },
  { '<C-f>', '<Right>' },
  { '<C-a>', '<Home>' },
  { '<C-e>', '<End>' },
  { '<C-d>', '<Del>' },
  { '<C-h>', '<BS>' },
})

tmap({ '<Esc>', [[<C-\><C-n>]] })
