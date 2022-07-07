local tmux = {}

function tmux.get_active_window()
  if os.getenv('$TERM_PROGRAM') ~= 'tmux' then
    return
  end
  local handle = io.popen('tmux list-windows')
  local output = handle:read('*a')
  handle:close()
  local lists = vim.split(output, '\n')
  local current_window_name = ''
  local all_windows = ''
  for i, v in pairs(lists) do
    if #v == 0 then
      table.remove(lists, i)
    else
      all_windows = all_windows .. ' ' .. v:match('%d:%s%w+')

      if v:find('active') then
        current_window_name = v:match('%d:%s%w+')
      end
    end
  end
  return all_windows
end

return tmux
