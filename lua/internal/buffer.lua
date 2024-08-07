local api = vim.api

local function next_buffer()
  local result = vim
    .iter(api.nvim_list_bufs())
    :filter(function(bufnr)
      return bufnr ~= api.nvim_get_current_buf()
        and api.nvim_buf_is_loaded(bufnr)
        and #vim.fn.win_findbuf(bufnr) == 0
    end)
    :totable()
  return result[1]
end

--- TODO: imporve with a buffer number
local function bdelete()
  local curwin = api.nvim_get_current_win()
  local win_pos = api.nvim_win_get_position(curwin)
  local curbuf = api.nvim_get_current_buf()
  local win_is_split = win_pos[1] > 0 or win_pos[2] > 0
  if not win_is_split then
    vim.cmd.bdelete()
    return
  end
  local nextbuf = next_buffer()
  if not nextbuf then
    vim.cmd.bdelete()
    return
  end
  api.nvim_win_set_buf(curwin, nextbuf)
  api.nvim_buf_delete(curbuf, { force = true })
end

api.nvim_create_user_command('BufKeepDelete', bdelete, {})
