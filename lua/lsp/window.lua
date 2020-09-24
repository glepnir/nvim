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

local function make_border_option(contents,opts)
  opts = opts or {}
  local win_width,win_height = vim.lsp.util._make_floating_popup_size(contents,opts)
  local border_option = M.make_floating_popup_options(win_width+2, win_height+2, opts)
  return win_width+2,win_height,border_option
end


local function create_float_boder(contents,border,opts)
  local win_width,win_height,border_option = make_border_option(contents,opts)

  local top_left = border_style[border].top_left
  local top_mid  = border_style[border].top_mid
  local top_right = border_style[border].top_right
  local mid_line = border_style[border].mid
  local bottom_left= border_style[border].bottom_left
  local bottom_right = border_style[border].bottom_right
  -- set border
  local top = top_left .. vim.fn["repeat"](top_mid, win_width-2) ..top_right
  local mid = mid_line .. vim.fn["repeat"](" ", win_width-2) .. mid_line
  local bot = bottom_left .. vim.fn["repeat"](top_mid, win_width-2) .. bottom_right
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
  local border_winid = api.nvim_open_win(border_bufnr, false, border_option)
  api.nvim_win_set_option(border_winid,"winhl","Normal:LspFloatWinBorder")
  api.nvim_win_set_option(border_winid,"cursorcolumn",false)
  return border_bufnr,border_winid
end

local function create_float_contents(contents, filetype,enter,modifiable,opts)
  -- create contents buffer
  local contents_bufnr = api.nvim_create_buf(false, true)
  -- buffer settings for contents buffer
  -- Clean up input: trim empty lines from the end, pad
  local content = vim.lsp.util._trim_and_pad(contents,{pad_left=0,pad_right=0})

  if filetype then
    api.nvim_buf_set_option(contents_bufnr, 'filetype', filetype)
  end
  api.nvim_buf_set_lines(contents_bufnr,0,-1,true,content)
  api.nvim_buf_set_option(contents_bufnr, 'modifiable', modifiable)
  local contents_winid = api.nvim_open_win(contents_bufnr, enter, opts)
  if filetype == 'markdown' then
    api.nvim_win_set_option(contents_winid, 'conceallevel', 2)
  end
  api.nvim_win_set_option(contents_winid,"winhl","Normal:LspNvim")
  return contents_bufnr, contents_winid
end

function M.create_float_window(contents,filetype,border,enter,modifiable,opts)
  local _,_,border_option = make_border_option(contents,opts)
  border_option.width = border_option.width - 2
  border_option.height = border_option.height - 2
  if border_option.row ~= 0 then
    border_option.row = border_option.row + 1
  else
    border_option.row = border_option.row - 1
  end
  border_option.col = border_option.col + 1
  if enter then
    local _,border_winid = create_float_boder(contents,border,opts)
    local contents_bufnr,contents_winid = create_float_contents(contents,filetype,enter,modifiable,border_option)
    return contents_bufnr,contents_winid,border_winid
  else
    local contents_bufnr,contents_winid = create_float_contents(contents,filetype,enter,modifiable,border_option)
    local _,border_winid = create_float_boder(contents,border,opts)
    return contents_bufnr,contents_winid,border_winid
  end
end

return M
