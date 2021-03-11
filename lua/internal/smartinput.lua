local sinput = {}
local api = vim.api

local delete_chars = function (times)
  local delete = '<BS>'
  local key = api.nvim_replace_termcodes(delete,true,true,true)
  return string.rep(key,times)
end

function _G.smart_input_loop(loop1,loop2)
  local col = api.nvim_win_get_cursor(0)[2]
  local content = api.nvim_get_current_line()
  local pchars1 = content:sub(col - #loop1 + 1,col)
  local pchars2 = content:sub(col - #loop2 + 1,col)

  if pchars1 == loop1 then
    return delete_chars(#loop1) .. loop2
  end
  if pchars2 == loop2 then
    return delete_chars(#loop1) .. loop1
  end
  if pchars1 ~= loop1 and pchars2 ~= loop2 then
    return loop1
  end
end

vim.cmd [[autocmd Filetype go inoremap <buffer><expr> ; v:lua.smart_input_loop(':=',';')]]

return sinput
