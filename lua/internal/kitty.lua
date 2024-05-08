vim.opt.encoding = 'utf-8'
vim.opt.compatible = false
vim.opt.clipboard = 'unnamedplus'
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.termguicolors = true
vim.opt.showmode = false
vim.opt.stc = ''
vim.opt.ruler = false
vim.opt.laststatus = 0
vim.opt.showcmd = false
vim.opt.scrollback = 1000

vim.api.nvim_set_hl(0, 'Normal', { bg = 'NONE' })

local term_buf = vim.api.nvim_create_buf(true, false)
local term_io = vim.api.nvim_open_term(term_buf, {})
vim.api.nvim_buf_set_keymap(term_buf, 'n', 'q', '<Cmd>q<CR>', {})
local group = vim.api.nvim_create_augroup('kitty+page', {})

vim.api.nvim_create_autocmd('VimEnter', {
  group = group,
  pattern = '*',
  once = true,
  callback = function(ev)
    local nlines = os.getenv('INPUT_LINE_NUMBER') or 0
    local cur_line = os.getenv('CURSOR_LINE') or 0
    local cur_column = os.getenv('CURSOR_COLUMN') or 0

    local current_win = vim.api.nvim_get_current_win()
    for _, line in ipairs(vim.api.nvim_buf_get_lines(ev.buf, 0, -1, false)) do
      vim.api.nvim_chan_send(term_io, line)
      vim.api.nvim_chan_send(term_io, '\r\n')
    end
    term_io = false
    vim.api.nvim_create_autocmd('ModeChanged', {
      group = group,
      pattern = '([nN]:[^vV])|([vV]:[^nN])',
      command = 'stopinsert',
    })
    vim.api.nvim_win_set_buf(current_win, term_buf)
    if nlines ~= vim.NIL and cur_line ~= vim.NIL and cur_column ~= vim.NIL then
      vim.api.nvim_win_set_cursor(
        current_win,
        { vim.fn.max({ 1, nlines }) + cur_line, cur_column > 1 and cur_column - 1 or 0 }
      )
    else
      vim.api.nvim_input([[<C-\><C-n>G]])
    end
    vim.api.nvim_buf_delete(ev.buf, { force = true })
  end,
})

vim.api.nvim_create_autocmd('TextYankPost', {
  command = 'call feedkeys("q")',
})
