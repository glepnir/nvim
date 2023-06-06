local map = require('core.keymap')
local cmd = map.cmd

map.n({
  ['j'] = 'gj',
  ['k'] = 'gk',
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
  ['<A-[>'] = cmd('vertical resize -5'),
  ['<A-]>'] = cmd('vertical resize +5'),
})

map.i({
  ['<C-d>'] = '<C-o>diw',
  ['<C-b>'] = '<Left>',
  ['<C-f>'] = '<Right>',
  ['<C-a>'] = '<Esc>^i',
  ['<C-k>'] = '<C-o>d$',
  ['<C-s>'] = '<ESC>:w<CR>',
  ['<C-n>'] = '<Down>',
  ['<C-p>'] = '<Up>',
  --down/up
  ['<C-j>'] = '<C-o>o',
  ['<C-l>'] = '<C-o>O',
  --@see https://github.com/neovim/neovim/issues/16416
  ['<C-C>'] = '<C-C>',
  --@see https://vim.fandom.com/wiki/Moving_lines_up_or_down
  ['<A-j>'] = '<Esc>:m .+1<CR>==gi',
  ['<A-k>'] = '<Esc>:m .-2<CR>==gi',
})

map.i('<C-h>', function()
  local ok, pairs = pcall(require, 'nvim-autopairs')
  if ok then
    return pairs.autopairs_bs()
  end
  return '<C-h>'
end, { expr = true, replace_keycodes = false })

map.i('<c-e>', function()
  return vim.fn.pumvisible() == 1 and '<C-e>' or '<Esc>g_a'
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
