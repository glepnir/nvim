local vim,api = vim,vim.api
local M = {}

function M.create_float_window(contents)
  -- get the editor's max width and height
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

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
    relative = "editor",
    style = "minimal",
    width = win_width,
    height = win_height,
    row = vim.fn.line('.'),
    col = math.ceil((width - win_width) / 2)
  }
  -- set border
  local top = "╭" .. vim.fn["repeat"]("─", win_width - 2) .. "╮"
  local mid = "│" .. vim.fn["repeat"](" ", win_width - 2) .. "│"
  local bot = "╰" .. vim.fn["repeat"]("─", win_width - 2) .. "╯"
  local lines = {top}
  for _,v in pairs(vim.fn["repeat"]({mid},win_height-2)) do
    table.insert(lines,v)
  end
  table.insert(lines,bot)
  local border_bufnr = vim.api.nvim_create_buf(false, true)
  -- buffer settings for border buffer
  api.nvim_buf_set_lines(border_bufnr, 0, -1, true, lines)
  api.nvim_buf_set_option(border_bufnr, 'buftype', 'nofile')
  api.nvim_buf_set_option(border_bufnr, 'filetype', 'lspwinborder')
  api.nvim_buf_set_option(border_bufnr, 'modifiable', false)
  -- create border
  local border_winid = api.nvim_open_win(border_bufnr, true, opts)
  api.nvim_win_set_option(border_winid,"winhl","Normal:LspFloatWinBorder")
  api.nvim_win_set_option(border_winid,"cursorcolumn",false)
  api.nvim_command("hi LspFloatWinBorder guifg=#6699cc")

  -- rewrite opts for contents buffer
  opts.row = opts.row + 1
  opts.height = opts.height - 2
  opts.col = opts.col + 2
  opts.width = opts.width - 4
  -- create contents buffer
  local contents_bufnr = api.nvim_create_buf(false, true)
  -- buffer settings for contents buffer
  -- Clean up input: trim empty lines from the end, pad
  contents = vim.lsp.util._trim_and_pad(contents, opts)
  api.nvim_buf_set_lines(contents_bufnr,0,-1,true,contents)
  api.nvim_buf_set_option(contents_bufnr, 'filetype', 'lspnvim')
  api.nvim_buf_set_option(contents_bufnr, 'modifiable', false)
  local contents_winid = api.nvim_open_win(contents_bufnr, true, opts)
  api.nvim_win_set_option(contents_winid,"winhl","Normal:LspNvim")

  return contents_bufnr,contents_winid
end

return M
