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

map.i('<TAB>', function()
  if vim.snippet.jumpable(1) then
    return '<cmd>lua vim.snippet.jump(1)<cr>'
  elseif vim.fn.pumvisible() == 1 then
    return '<C-n>'
  else
    return '<TAB>'
  end
end, { expr = true })

map.i('<S-TAB>', function()
  if vim.snippet.jumpable(-1) then
    return '<cmd>lua vim.snippet.jump(-1)<CR>'
  elseif vim.fn.pumvisible() == 1 then
    return '<C-p>'
  else
    return '<S-TAB>'
  end
end, { expr = true })

local function feedkeys(key, mode)
  local keycode = vim.api.nvim_replace_termcodes(key, true, false, true)
  vim.api.nvim_feedkeys(keycode, mode, false)
end

map.i('<CR>', function()
  local p = require('mini.pairs')
  if vim.fn.pumvisible() == 1 then
    feedkeys('<C-y>', 'n')
  else
    p.cr()
  end
end, { expr = true })

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
