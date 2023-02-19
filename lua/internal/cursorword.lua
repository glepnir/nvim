local api, fn = vim.api, vim.fn

local function disable_cursorword()
  if vim.w.cursorword_id ~= 0 and vim.w.cursorword_id and vim.w.cursorword_match ~= 0 then
    fn.matchdelete(vim.w.cursorword_id)
    vim.w.cursorword_id = nil
    vim.w.cursorword_match = nil
    vim.w.cursorword = nil
  end
end

local function matchadd()
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

local function cursor_moved(buf)
  local ignored = { 'terminal', 'prompt', 'help', 'nofile' }
  if
    vim.tbl_contains(ignored, vim.bo[buf].buftype)
    or vim.tbl_contains(ignored, vim.bo.filetype)
    or #vim.bo.filetype == 0
    or api.nvim_get_mode().mode == 'i'
  then
    return
  end
  matchadd()
end

return {
  cursor_moved = cursor_moved,
  disable_cursorword = disable_cursorword,
}
