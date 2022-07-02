local keymap = require('core.keymap')
local map,silent,noremap = keymap.map,keymap.silent,keymap.noremap
local expr = keymap.expr
local opts = keymap.new_opts
local cmd = keymap.cmd

map {
  -- noremal remap
  -- close buffer
  {'n',"<C-x>k",cmd('bdelete'),opts(noremap,silent)},
  -- save
  {'n',"<C-s>",cmd('write'),opts(noremap)},
  -- yank
  {'n',"Y",'y$',opts(noremap)},
  -- buffer jump
  {'n',"]b",cmd('bp'),opts(noremap)},
  {'n',"[b",cmd('bp'),opts(noremap)},
  -- remove trailing white space
  {'n',"<Leader>t",cmd('TrimTrailingWhitespace'),opts(noremap)},
  -- window jump
  {'n',"<C-h>",'<C-w>h',opts(noremap)},
  {'n',"<C-l>",'<C-w>l',opts(noremap)},
  {'n',"<C-j>",'<C-w>j',opts(noremap)},
  {'n',"<C-k>",'<C-w>k',opts(noremap)},
  -- resize window
  {'n',"<A-[>",cmd('vertical resize -5'),opts(noremap,silent)},
  {'n',"<A-]>",cmd('vertical resize +5'),opts(noremap,silent)},

  -- insertmode remap
  {'i',"<C-w>",'<C-[>diwa',opts(noremap)},
  {'i',"<C-h>",'<Bs>',opts(noremap)},
  {'i',"<C-d>",'<Del>',opts(noremap)},
  {'i',"<C-u>",'<C-G>u<C-u>',opts(noremap)},
  {'i',"<C-b>",'<Left>',opts(noremap)},
  {'i',"<C-f>",'<Right>',opts(noremap)},
  {'i',"<C-a>",'<Esc>^i',opts(noremap)},
  {'i',"<C-j>",'<Esc>o',opts(noremap)},
  {'i',"<C-k>",'<Esc>O',opts(noremap)},
  {'i',"<C-s>",'<ESC>:w<CR>',opts(noremap)},
  {'i',"<C-e>",function()
    return vim.fn.pumvisible() == 1 and "<C-e>" or "<end>"end,opts(expr)},

  -- commandline remap
  {'c','<C-b>','<Left>',opts(noremap)},
  {'c','<C-f>','<Right>',opts(noremap)},
  {'c','<C-a>','<Home>',opts(noremap)},
  {'c','<C-e>','<End>',opts(noremap)},
  {'c','<C-d>','<Del>',opts(noremap)},
  {'c','<C-h>','<BS>',opts(noremap)},
}

