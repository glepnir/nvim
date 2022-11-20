local api, fn = vim.api, vim.fn

local function highlight_cursorword()
  if vim.g.cursorword_highlight ~= false then
    api.nvim_set_hl(0, 'CursorWord', { underline = true })
  end
end

local function disable_cursorword()
  if vim.w.cursorword_id ~= 0 and vim.w.cursorword_id and vim.w.cursorword_match ~= 0 then
    fn.matchdelete(vim.w.cursorword_id)
    vim.w.cursorword_id = nil
    vim.w.cursorword_match = nil
    vim.w.cursorword = nil
  end
end

local function matchadd()
  local bufname = api.nvim_buf_get_name(0)
  if vim.bo.buftype == 'prompt' or #bufname == 0 then
    return
  end

  if api.nvim_get_mode().mode == 'i' then
    return
  end

  local column = api.nvim_win_get_cursor(0)[2]
  local line = api.nvim_get_current_line()
  local cursorword = fn.matchstr(line:sub(1, column + 1), [[\k*$]])
    .. fn.matchstr(line:sub(column + 1), [[^\k*]]):sub(2)

  if cursorword == vim.w.cursorword then
    return
  end
  vim.w.cursorword = cursorword
  if vim.w.cursorword_match == 1 then
    vim.call('matchdelete', vim.w.cursorword_id)
  end
  vim.w.cursorword_match = 0
  if
    cursorword == ''
    or #cursorword > 100
    or #cursorword < 3
    or string.find(cursorword, '[\192-\255]+') ~= nil
  then
    return
  end
  local pattern = [[\<]] .. cursorword .. [[\>]]
  vim.w.cursorword_id = fn.matchadd('CursorWord', pattern, -1)
  vim.w.cursorword_match = 1
end

local function cursor_moved()
  if api.nvim_get_mode().mode == 'n' then
    matchadd()
  end
end

highlight_cursorword()

api.nvim_create_autocmd({ 'CursorMoved' }, {
  pattern = '*',
  callback = cursor_moved,
})

api.nvim_create_autocmd({ 'InsertEnter', 'BufWinEnter' }, {
  pattern = '*',
  callback = disable_cursorword,
})
