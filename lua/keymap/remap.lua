local map = require('core.keymap')
local cmd = map.cmd

map.n({
  ['<C-s>'] = cmd('write'),
  ['<C-x>k'] = cmd('bdelete'),
  ['<C-n>'] = cmd('bn'),
  ['<C-p>'] = cmd('bp'),
  ['<C-q>'] = cmd('qa!'),
  --window
  ['<C-h>'] = '<C-w>h',
  ['<C-l>'] = '<C-w>l',
  ['<C-j>'] = '<C-w>j',
  ['<C-k>'] = '<C-w>k',
  ['<A-[>'] = 'vertical resize -5',
  ['<A-]>'] = 'vertical resize +5',
})

map.i({
  ['<C-w>'] = '<C-[>diwa',
  ['<C-h>'] = '<Bs>',
  ['<C-d>'] = '<Del>',
  ['<C-u>'] = '<C-G>u<C-u>',
  ['<C-b>'] = '<Left>',
  ['<C-f>'] = '<Right>',
  ['<C-a>'] = '<Esc>^i',
  ['<C-j>'] = '<Esc>o',
  ['<C-k>'] = '<Esc>O',
  ['<C-s>'] = '<ESC>:w<CR>',
})

map.i('<c-e>', function()
  return vim.fn.pumvisible() == 1 and '<C-e>' or '<End>'
end, { expr = true })

map.c({
  ['<C-b>'] = '<Left>',
  ['<C-f>'] = '<Right>',
  ['<C-a>'] = '<Home>',
  ['<C-e>'] = '<End>',
  ['<C-d>'] = '<Del>',
  ['<C-h>'] = '<BS>',
})

map.t('<Esc>', [[<C-\><C-n>]])
