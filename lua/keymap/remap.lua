local map = require('core.keymap')
local cmd = map.cmd

map.n({
  ['<C-s>'] = cmd('write'),
  ['<C-x>k'] = cmd('bdelete'),
  ['<C-n'] = cmd('bn'),
  ['<C-p'] = cmd('bp'),
  ['<C-q>'] = cmd('qa!'),
  --window
  ['<C-h>'] = cmd('<C-w>h'),
  ['<C-l>'] = cmd('<C-w>l'),
  ['<C-j>'] = cmd('<C-w>j'),
  ['<C-k>'] = cmd('<C-w>k'),
  ['<A-[>'] = cmd('vertical resize -5'),
  ['<A-]>'] = cmd('vertical resize +5'),
})

map.i({
  ['<C-w>'] = cmd('<C-[>diwa'),
  ['<C-h>'] = cmd('<Bs>'),
  ['<C-d>'] = cmd('<Del>'),
  ['<C-u>'] = cmd('<C-G>u<C-u>'),
  ['<C-b>'] = cmd('<Left>'),
  ['<C-f>'] = cmd('<Right>'),
  ['<C-a>'] = cmd('<Esc>^i'),
  ['<C-j>'] = cmd('<Esc>o'),
  ['<C-k>'] = cmd('<Esc>O'),
  ['<C-s>'] = cmd('<ESC>:w<CR>'),
})

map.i('<c-e>', function()
  return vim.fn.pumvisible() == 1 and '<C-e>' or '<End>'
end, { expr = true })

map.c({
  ['<C-b>'] = cmd('<Left>'),
  ['<C-f>'] = cmd('<Right>'),
  ['<C-a>'] = cmd('<Home>'),
  ['<C-e>'] = cmd('<End>'),
  ['<C-d>'] = cmd('<Del>'),
  ['<C-h>'] = cmd('<BS>'),
})

map.t('<Esc>', [[<C-\><C-n>]])
