local api = vim.api
local ns = api.nvim_create_namespace('indent')
local augroup = api.nvim_create_augroup('indentlines', {})
local ffi = require('ffi')
local ts = vim.treesitter

local opt = {
  enabled = true,
  char = '┆',
  hl = 'Whitespace',
  minlevel = 1,
  ts_exclude_nodetype = { 'comment', 'string' },
  exclude_filetype = { 'help', 'dashboard', 'diff', 'fzf', 'markdown' },
  avoid_cursor_in_insert = true,
}

local function guides(sw)
  if vim.list_contains(opt.exclude_filetype, vim.bo.filetype) then
    return
  end
  if sw == 0 then
    sw = vim.bo.tabstop
  end
  local indent_char = opt.char .. (' '):rep(sw - 1)
  vim.opt_local.listchars:append({ leadmultispace = indent_char })
end

api.nvim_create_autocmd('OptionSet', {
  pattern = { 'shiftwidth', 'tabstop', 'expandtab' },
  group = augroup,
  callback = function()
    if type(vim.v.option_new) ~= 'boolean' then
      guides(vim.v.option_new)
    end
  end,
})

api.nvim_create_autocmd({ 'BufWinEnter', 'BufEnter' }, {
  group = augroup,
  callback = function(args)
    guides(vim.bo[args.buf].shiftwidth)
  end,
})

if vim.v.vim_did_enter then
  guides(vim.bo.shiftwidth)
end

ffi.cdef([[
  typedef struct {} Error;
  typedef struct file_buffer buf_T;
  typedef int32_t linenr_T;
  buf_T *find_buffer_by_handle(int buffer, Error *err);
  int get_sw_value(buf_T *buf);
  int get_indent_buf(buf_T *buf, linenr_T lnum);
  char *ml_get_buf(buf_T *buf, linenr_T lnum);
]])

local C = ffi.C
local ml_get_buf = C.ml_get_buf
local get_indent_buf = C.get_indent_buf
local find_buffer_by_handle = C.find_buffer_by_handle
local get_sw_value = C.get_sw_value
local UP, DOWN = -1, 1

local function get_step(bufnr)
  local handle = find_buffer_by_handle(bufnr, ffi.new('Error'))
  local sw = get_sw_value(handle)
  if sw == 0 then
    sw = vim.bo[bufnr].tabstop
  end
  return sw
end

local function buf_get_line(bufnr, row)
  local handle = find_buffer_by_handle(bufnr, ffi.new('Error'))
  return ffi.string(ml_get_buf(handle, row + 1))
end

local function buf_get_indent(bufnr, lnum)
  local handle = find_buffer_by_handle(bufnr, ffi.new('Error'))
  return get_indent_buf(handle, lnum)
end

--- @param text string
--- @return boolean
local function is_blank(text)
  if not text or #text == 0 then
    return true
  end
  for i = 1, #text do
    local byte = string.byte(text, i)
    if byte ~= 32 and byte ~= 9 then
      return false
    end
  end
  return true
end

local ctx = {}

--- @param c table
--- @param row integer 0-indexed
--- @param direction integer UP(-1) or DOWN(1)
--- @param bufnr integer
--- @return integer
local function search_nearest(c, row, direction, bufnr)
  local r = row
  while r >= 0 and r < c.count do
    if c.nonblank[r] then
      return c.nonblank[r]
    end
    local text = buf_get_line(bufnr, r)
    if not is_blank(text) then
      local indent = buf_get_indent(bufnr, r + 1)
      c.nonblank[r] = indent
      return indent
    end
    r = r + direction
  end
  return 0
end

--- @param c table
--- @param bufnr integer
--- @param row integer 0-indexed
--- @param has_ts boolean
local function blank_indent(c, bufnr, row, has_ts)
  if has_ts then
    local node = ts.get_node({ bufnr = bufnr, pos = { row, 0 } })
    if not node then
      return
    end
    c.tree_root = c.tree_root or node:tree():root():type()
    if c.tree_root and node:type() ~= c.tree_root then
      local parent = node:parent()
      if parent then
        local p_srow = parent:range()
        if p_srow >= 0 then
          c.indent[row] = (
            c.nonblank[p_srow] and c.nonblank[p_srow] or buf_get_indent(bufnr, p_srow + 1)
          ) + c.step
        end
      end
    end
  else
    local up = search_nearest(c, row - 1, UP, bufnr)
    local down = search_nearest(c, row + 1, DOWN, bufnr)
    local indent = math.max(up, down)
    if indent > 0 then
      c.indent[row] = indent
    end
  end
end

local function build_cache(winid, bufnr, toprow, botrow, has_ts)
  ctx[winid] = {}
  local c = ctx[winid]
  c.step = get_step(bufnr)
  c.tabstop = vim.bo[bufnr].tabstop
  c.leftcol = vim.fn.winsaveview().leftcol
  c.count = api.nvim_buf_line_count(bufnr)
  c.blank = {}
  c.nonblank = {}
  c.indent = {}

  local mode = api.nvim_get_mode().mode
  c.insert = mode == 'i' or mode == 'ic' or mode == 'ix'
  if c.insert then
    local pos = api.nvim_win_get_cursor(0)
    c.currow = pos[1] - 1
    c.curcol = pos[2]
  end

  for i = toprow, botrow do
    local line_text = buf_get_line(bufnr, i)
    if is_blank(line_text) then
      c.blank[i] = true
    else
      c.nonblank[i] = buf_get_indent(bufnr, i + 1)
    end
  end

  for row in pairs(c.blank) do
    blank_indent(c, bufnr, row, has_ts)
  end
end

api.nvim_set_decoration_provider(ns, {
  on_win = function(_, winid, bufnr, toprow, botrow)
    if
      not opt.enabled
      or vim.list_contains(opt.exclude_filetype, vim.bo[bufnr].filetype)
      or vim.list_contains({ 'nofile', 'prompt' }, vim.bo[bufnr].buftype)
    then
      return false
    end
    build_cache(winid, bufnr, toprow, botrow, ts.highlighter.active[bufnr])
  end,
  on_line = function(_, winid, bufnr, row)
    local c = ctx[winid]
    if not c or not c.blank[row] then
      return
    end

    local indent = c.indent[row]
    if not indent or indent <= 0 then
      return
    end

    local step = c.step > 0 and c.step or c.tabstop
    if step <= 0 then
      return
    end

    local levels = math.floor(indent / step)

    for level = opt.minlevel, levels do
      local col = (level - 1) * step

      if col < c.leftcol or col >= indent then
        goto continue
      end

      if opt.avoid_cursor_in_insert and c.insert and row == c.currow and col == c.curcol then
        goto continue
      end

      api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
        virt_text = { { opt.char, opt.hl } },
        virt_text_pos = 'overlay',
        hl_mode = 'combine',
        ephemeral = true,
        virt_text_win_col = col - c.leftcol,
      })

      ::continue::
    end
  end,
})
