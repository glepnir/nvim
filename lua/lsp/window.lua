local vim,api = vim,vim.api
local M = {}

-- 1 thin
-- 2 radio
-- 3 crude
local border_style = {
  {top_left = "┌",top_mid = "─",top_right = "┐",mid = "│",bottom_left = "└",bottom_right= "┘" };
  {top_left = "╭",top_mid = "─",top_right = "╮",mid = "│",bottom_left = "╰",bottom_right= "╯" };
  {top_left = "┏",top_mid = "━",top_right = "┓",mid = "┃",bottom_left = "┗",bottom_right = "┛"};
}

function M.create_float_window(contents,border)
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
    row = vim.fn.line('.') ,
    col = math.ceil((width - win_width) / 2)
  }

  local top_left = border_style[border].top_left
  local top_mid  = border_style[border].top_mid
  local top_right = border_style[border].top_right
  local mid_line = border_style[border].mid
  local bottom_left= border_style[border].bottom_left
  local bottom_right = border_style[border].bottom_right
  -- set border
  local top = top_left .. vim.fn["repeat"](top_mid, win_width - 2) ..top_right
  local mid = mid_line .. vim.fn["repeat"](" ", win_width - 2) .. mid_line
  local bot = bottom_left .. vim.fn["repeat"](top_mid, win_width - 2) .. bottom_right
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

  -- rewrite opts for contents buffer
  opts.row = opts.row + 1
  opts.height = opts.height - 2
  opts.col = opts.col + 1
  opts.width = opts.width - 4
  -- create contents buffer
  local contents_bufnr = api.nvim_create_buf(false, true)
  -- buffer settings for contents buffer
  -- Clean up input: trim empty lines from the end, pad
  local content = vim.lsp.util._trim_and_pad(contents,{pad_left=0})
  api.nvim_buf_set_lines(contents_bufnr,0,-1,true,content)
  api.nvim_buf_set_option(contents_bufnr, 'filetype', 'lspnvim')
  api.nvim_buf_set_option(contents_bufnr, 'modifiable', true)
  local contents_winid = api.nvim_open_win(contents_bufnr, true, opts)
  api.nvim_win_set_option(contents_winid,"winhl","Normal:LspNvim")
  return contents_bufnr,contents_winid,border_winid
end

function M.open_floating_preview(contents, filetype, opts)
  opts = opts or {}

  -- Clean up input: trim empty lines from the end, pad
  contents = vim.lsp.util._trim_and_pad(contents, opts)

  -- Compute size of float needed to show (wrapped) lines
  opts.wrap_at = opts.wrap_at or (vim.wo["wrap"] and api.nvim_win_get_width(0))
  local width, height = vim.lsp.util._make_floating_popup_size(contents, opts)

  local floating_bufnr = api.nvim_create_buf(false, true)
  if filetype then
    api.nvim_buf_set_option(floating_bufnr, 'filetype', filetype)
  end
  local float_option = vim.lsp.util.make_floating_popup_options(width, height, opts)
  local floating_winnr = api.nvim_open_win(floating_bufnr, false, float_option)
  if filetype == 'markdown' then
    api.nvim_win_set_option(floating_winnr, 'conceallevel', 2)
  end
  api.nvim_buf_set_lines(floating_bufnr, 0, -1, true, contents)
  api.nvim_buf_set_option(floating_bufnr, 'modifiable', false)
  return floating_bufnr, floating_winnr
end

return M
