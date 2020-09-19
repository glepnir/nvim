local global = require('global')
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

function M.get_max_contents_width(contents)
  local max_length = 0
  for i=1,#contents-1,1 do
    if #contents[i] > #contents[i+1] then
      max_length = #contents[i]
    end
  end
  return max_length
end

function M.make_floating_popup_options(width, height, opts)
  vim.validate {
    opts = { opts, 't', true };
  }
  opts = opts or {}
  vim.validate {
    ["opts.offset_x"] = { opts.offset_x, 'n', true };
    ["opts.offset_y"] = { opts.offset_y, 'n', true };
  }
  local new_option = {}

  new_option.style = 'minimal'
  new_option.width = width
  new_option.height = height
  if opts.relative ~= nil then
    new_option.relative = opts.relative
  else
    new_option.relative = 'cursor'
  end

  if opts.anchor ~= nil then
    new_option.anchor = opts.anchor
  end

  if opts.row == nil and opts.col == nil then

    local lines_above = vim.fn.winline() - 1
    local lines_below = vim.fn.winheight(0) - lines_above
    new_option.anchor = ''

    if lines_above < lines_below then
      new_option.anchor = new_option.anchor..'N'
      height = math.min(lines_below, height)
      new_option.row = 1
    else
      new_option.anchor = new_option.anchor..'S'
      height = math.min(lines_above, height)
      new_option.row = 0
    end

    if vim.fn.wincol() + width <= api.nvim_get_option('columns') then
      new_option.anchor = new_option.anchor..'W'
      new_option.col = 0
    else
      new_option.anchor = new_option.anchor..'E'
      new_option.col = 1
    end
  else
    new_option.row = opts.row
    new_option.col = opts.col
  end

  return new_option
end

function M.create_float_window(contents,filetype,border,opts)
  -- local win_width = M.get_max_contents_width(contents)
  -- local win_height = #contents + 2
  opts = opts or {}
  local win_width,win_height = vim.lsp.util._make_floating_popup_size(contents,opts)
  if opts == {} then
    opts.wrap_at = opts.wrap_at or (vim.wo["wrap"] and api.nvim_win_get_width(0))
    opts = M.make_floating_popup_options(win_width, win_height+2, opts)
  else
    opts.width = win_width
    opts.height = win_height + 2
  end

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
  for _,v in pairs(vim.fn["repeat"]({mid},win_height)) do
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
  local content = vim.lsp.util._trim_and_pad(contents,{pad_left=0,pad_right=0})
  api.nvim_buf_set_lines(contents_bufnr,0,-1,true,content)
  if filetype then
    api.nvim_buf_set_option(contents_bufnr, 'filetype', filetype)
  end
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
