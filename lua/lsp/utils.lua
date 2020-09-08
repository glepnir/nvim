local vim,api = vim,vim.api
local M = {}

function M.create_float_window(contents,opts)
  opts = opts or {}
  -- Clean up input: trim empty lines from the end, pad
  contents = vim.lsp.util._trim_and_pad(contents, opts)
  -- get the editor's max width and height
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  -- create a new, scratch buffer, for fzf
  local floating_bufnr = vim.api.nvim_create_buf(false, true)
  local floating_winnr = nil
  api.nvim_buf_set_lines(floating_bufnr, 0, -1, true, contents)
  api.nvim_buf_set_option(floating_bufnr, 'filetype', 'markdown')
  api.nvim_buf_set_option(floating_bufnr, 'modifiable', false)

  -- if the editor is big enough
  if (width > 150 or height > 35) then
    local win_height = math.min(math.ceil(height * 3 / 4), 30)
    local win_width

    -- if the width is small
    if (width < 150) then
      -- just subtract 8 from the editor's width
      win_width = math.ceil(width - 8)
    else
      -- use 90% of the editor's width
      win_width = math.ceil(width * 0.9)
    end

    -- settings for the float window
    local opts = {
      relative = "cursor",
      style = "minimal",
      width = win_width,
      height = win_height,
      row = math.ceil((height - win_height) / 2),
      col = math.ceil((width - win_width) / 2)
    }

    -- create a new floating window, centered in the editor
    floating_winnr = vim.api.nvim_open_win(floating_bufnr, true, opts)
  end
  return floating_bufnr,floating_winnr
end

return M
