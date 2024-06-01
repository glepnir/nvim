local api = vim.api
local map = require('core.keymap')
local cmd = map.cmd
map.n({
  ['j'] = 'gj',
  ['k'] = 'gk',
  ['<C-s>'] = cmd('write'),
  ['<C-x>k'] = cmd(vim.bo.buftype == 'terminal' and 'q!' or 'bdelete!'),
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
  ['[t'] = cmd('vs | vertical resize -5 | terminal'),
  [']t'] = cmd('set splitbelow | sp | set nosplitbelow | resize -5 | terminal'),
  ['<C-x>t'] = cmd('tabnew | terminal'),
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
})

map.c({
  ['<C-b>'] = '<Left>',
  ['<C-f>'] = '<Right>',
  ['<C-a>'] = '<Home>',
  ['<C-e>'] = '<End>',
  ['<C-d>'] = '<Del>',
  ['<C-h>'] = '<BS>',
})

map.t({
  ['<Esc>'] = [[<C-\><C-n>]],
  ['<C-x>k'] = cmd('quit'),
})

-- insert cut text to paste
map.i('<A-w>', function()
  local mark = vim.api.nvim_buf_get_mark(0, 'a')
  local lnum, col = unpack(api.nvim_win_get_cursor(0))
  if mark[1] == 0 then
    api.nvim_buf_set_mark(0, 'a', lnum, col, {})
  else
    local keys = '<ESC>d`aa'
    api.nvim_feedkeys(api.nvim_replace_termcodes(keys, true, true, true), 'n', false)
    vim.schedule(function()
      api.nvim_buf_del_mark(0, 'a')
    end)
  end
end)

-- Ctrl-y works like emacs
map.i('<C-y>', function()
  if vim.fn.pumvisible() == 1 or #vim.fn.getreg('"') == 0 then
    return '<C-y>'
  end
  return '<Esc>p==a'
end, { expr = true })

-- move line down
map.i('<A-k>', function()
  local lnum = api.nvim_win_get_cursor(0)[1]
  local line = api.nvim_buf_get_lines(0, lnum - 3, lnum - 2, false)[1]
  return #line > 0 and '<Esc>:m .-2<CR>==gi' or '<Esc>kkddj:m .-2<CR>==gi'
end, { expr = true })

map.i('<TAB>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-n>'
  elseif vim.snippet.active({ direction = 1 }) then
    return '<cmd>lua vim.snippet.jump(1)<cr>'
  else
    return '<TAB>'
  end
end, { expr = true })

map.i('<S-TAB>', function()
  if vim.fn.pumvisible() == 1 then
    return '<C-p>'
  elseif vim.snippet.active({ direction = -1 }) then
    return '<cmd>lua vim.snippet.jump(-1)<CR>'
  else
    return '<S-TAB>'
  end
end, { expr = true })

map.i('<CR>', function()
  return vim.fn.pumvisible() == 1 and '<C-y>' or _G.PairMate.cr()
end, { expr = true })

map.i('<C-e>', function()
  if vim.fn.pumvisible() == 1 then
    require('epo').disable_trigger()
    return '<c-e>'
  else
    return '<End>'
  end
end, { expr = true })
