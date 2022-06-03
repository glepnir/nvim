local M = {}

function M.highlight_cursorword()
  if vim.g.cursorword_highlight ~= false then
    vim.cmd('highlight CursorWord term=underline cterm=underline gui=underline')
  end
end

function M.matchadd()
  if vim.fn.hlexists("CursorWord") == 0 then
    return
  end
  local column = vim.api.nvim_win_get_cursor(0)[2]
  local line = vim.api.nvim_get_current_line()
  local cursorword =
    vim.fn.matchstr(line:sub(1, column + 1), [[\k*$]]) .. vim.fn.matchstr(line:sub(column + 1), [[^\k*]]):sub(2)

  if cursorword == vim.w.cursorword then
    return
  end
  vim.w.cursorword = cursorword
  if vim.w.cursorword_match == 1 then
    vim.call("matchdelete", vim.w.cursorword_id)
  end
  vim.w.cursorword_match = 0
  if cursorword == "" or #cursorword > 100 or #cursorword < 3 or string.find(cursorword, "[\192-\255]+") ~= nil then
    return
  end
  local pattern = [[\<]] .. cursorword .. [[\>]]
  vim.w.cursorword_id = vim.fn.matchadd("CursorWord", pattern, -1)
  vim.w.cursorword_match = 1
end

function M.cursor_moved()
  if vim.api.nvim_get_mode().mode == 'n' then
    M.matchadd()
  end
end

return M
