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

-- For noexpandtab files the visual indent unit is tabstop, not shiftwidth.
-- get_indent_buf() returns visual columns (tab counts as tabstop cols), so the
-- step used to compute guide positions must match that same unit.
local function get_step(bufnr)
  if not vim.bo[bufnr].expandtab then
    return vim.bo[bufnr].tabstop
  end
  local handle = find_buffer_by_handle(bufnr, ffi.new('Error'))
  local sw = get_sw_value(handle)
  if sw == 0 then
    sw = vim.bo[bufnr].tabstop
  end
  return sw
end

local function guides(bufnr)
  if vim.list_contains(opt.exclude_filetype, vim.bo[bufnr].filetype) then
    return
  end
  if vim.bo[bufnr].expandtab then
    local sw = get_step(bufnr)
    local indent_char = opt.char .. (' '):rep(sw - 1)
    vim.opt_local.listchars:append({ leadmultispace = indent_char })
  end
end

api.nvim_create_autocmd('OptionSet', {
  pattern = { 'shiftwidth', 'tabstop', 'expandtab' },
  group = augroup,
  callback = function(args)
    if type(vim.v.option_new) ~= 'boolean' then
      guides(args.buf)
    end
  end,
})

api.nvim_create_autocmd({ 'BufWinEnter' }, {
  group = augroup,
  callback = function(args)
    guides(args.buf)
  end,
})

if vim.v.vim_did_enter then
  guides(0)
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

local function pack(is_empty, indent, is_toplevel)
  return bit.bor(
    bit.lshift(is_empty and 1 or 0, 15),
    bit.lshift(is_toplevel and 1 or 0, 14),
    bit.band(indent, 0x3FFF)
  )
end

local function unpack_empty(packed)
  return bit.band(bit.rshift(packed, 15), 1) == 1
end

local function unpack_toplevel(packed)
  return bit.band(bit.rshift(packed, 14), 1) == 1
end

local function unpack_indent(packed)
  return bit.band(packed, 0x3FFF)
end

--- @param c table
--- @param row integer 0-indexed
--- @param direction integer UP(-1) or DOWN(1)
--- @param bufnr integer
--- @return integer
local function search_nearest(c, row, direction, bufnr)
  local r = row
  while r >= 0 and r < c.count do
    local packed = c.snapshot[r]
    if packed and not unpack_empty(packed) then
      return unpack_indent(packed)
    end
    if not packed then
      local text = buf_get_line(bufnr, r)
      if not is_blank(text) then
        local indent = buf_get_indent(bufnr, r + 1)
        c.snapshot[r] = pack(false, indent)
        return indent
      end
      c.snapshot[r] = pack(true, 0)
    end
    r = r + direction
  end
  return 0
end

--- @param c table
--- @param bufnr integer
--- @param row integer 0-indexed
local function blank_indent(c, bufnr, row)
  if ts.highlighter.active[bufnr] then
    local node = ts.get_node({ bufnr = bufnr, pos = { row, 0 } })
    if not node then
      return
    end
    local node_type = node:type()
    c.tree_root = c.tree_root or node:tree():root():type()
    if c.tree_root and node_type ~= c.tree_root and not vim.startswith(node_type, 'ERROR') then
      local parent = node:parent()
      if parent then
        local p_srow = parent:range()
        if p_srow >= 0 then
          local p_packed = c.snapshot[p_srow]
          local p_indent = p_packed and unpack_indent(p_packed) or buf_get_indent(bufnr, p_srow + 1)
          c.snapshot[row] = pack(true, p_indent + c.step)
        end
      end
    end
  else
    local up = search_nearest(c, row - 1, UP, bufnr)
    local down = search_nearest(c, row + 1, DOWN, bufnr)
    local indent = math.max(up, down)
    if indent > 0 then
      c.snapshot[row] = pack(true, indent)
    end
  end
end

local function build_cache(winid, bufnr, toprow, botrow)
  local mode = api.nvim_get_mode().mode
  local insert = mode == 'i' or mode == 'ic' or mode == 'ix'
  local changedtick = api.nvim_buf_get_changedtick(bufnr)
  local prev = ctx[winid]
  if prev and (prev.bufnr ~= bufnr or (not insert and prev.changedtick ~= changedtick)) then
    ctx[winid] = {}
  else
    ctx[winid] = ctx[winid] or {}
  end

  local c = ctx[winid]
  c.bufnr = bufnr
  c.changedtick = changedtick
  c.snapshot = c.snapshot or {}
  c.step = get_step(bufnr)
  c.tabstop = vim.bo[bufnr].tabstop
  c.expandtab = vim.bo[bufnr].expandtab
  c.leftcol = vim.fn.winsaveview().leftcol
  c.count = api.nvim_buf_line_count(bufnr)
  c.insert = insert
  if insert then
    local pos = api.nvim_win_get_cursor(0)
    c.currow = pos[1] - 1
    c.curcol = pos[2]
  end

  local blanks = {}
  for i = toprow, botrow do
    local line_text = buf_get_line(bufnr, i)
    if is_blank(line_text) then
      if ts.highlighter.active[bufnr] then
        local node = ts.get_node({ bufnr = bufnr, pos = { i, 0 } })
        if node and node:type() == node:tree():root():type() then
          c.snapshot[i] = pack(true, 0, true)
          goto continue
        end
      end
      if insert and c.snapshot[i] then
        if unpack_toplevel(c.snapshot[i]) or unpack_indent(c.snapshot[i]) > 0 then
          goto continue
        end
      end
      blanks[#blanks + 1] = i
    else
      c.snapshot[i] = pack(false, buf_get_indent(bufnr, i + 1), false)
    end
    ::continue::
  end

  for _, row in ipairs(blanks) do
    blank_indent(c, bufnr, row)
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
    build_cache(winid, bufnr, toprow, botrow)
  end,
  on_line = function(_, winid, bufnr, row)
    local c = ctx[winid]
    if not c then
      return
    end

    local packed = c.snapshot[row]
    if not packed then
      return
    end

    if not unpack_empty(packed) and c.expandtab then
      return
    end

    local indent = unpack_indent(packed)
    if indent <= 0 then
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
