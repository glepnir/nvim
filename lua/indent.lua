local api = vim.api
local bit = require('bit')
local ffi = require('ffi')
local ts = vim.treesitter
local ns = api.nvim_create_namespace('indent')
local augroup = api.nvim_create_augroup('indentlines', {})

local opt = {
  enabled = true,
  char = '┆',
  hl = 'Whitespace',
  minlevel = 1,
  ts_exclude_nodetype = { 'comment', 'string' },
  exclude_filetype = { 'help', 'dashboard', 'agenda', 'diff', 'fzf', 'markdown', 'quickfix' },
  exclude_buftype = { 'nofile', 'prompt', 'quickfix', 'terminal' },
  avoid_cursor_in_insert = true,
}

ffi.cdef([[
  typedef struct { int type; char *msg; } Error;
  typedef struct file_buffer buf_T;
  typedef int32_t linenr_T;
  buf_T *find_buffer_by_handle(int buffer, Error *err);
  int get_indent_buf(buf_T *buf, linenr_T lnum);
  char *ml_get_buf(buf_T *buf, linenr_T lnum);
]])

local C = ffi.C
local ml_get_buf = C.ml_get_buf
local get_indent_buf = C.get_indent_buf
local find_buffer_by_handle = C.find_buffer_by_handle
local ffi_err = ffi.new('Error')

local function buf_handle(bufnr)
  local handle = find_buffer_by_handle(bufnr, ffi_err)
  if handle == nil then
    error(('indent: invalid buffer %d'):format(bufnr))
  end
  return handle
end

------------------------------------------------------------------------
-- 缩进单位
------------------------------------------------------------------------

-- get_indent_buf() 返回 visual column，缩进单位同样是 visual column 下的 shiftwidth
-- （sw=0 回退到 tabstop）。纯 tab 时 sw == ts，所以一个函数覆盖所有情况。
local function get_step(bufnr)
  local bo = vim.bo[bufnr]
  local sw = bo.shiftwidth
  return sw > 0 and sw or bo.tabstop
end

local function is_pure_tab(bufnr)
  local bo = vim.bo[bufnr]
  if bo.expandtab then
    return false
  end
  local tabstop, sw, sts = bo.tabstop, bo.shiftwidth, bo.softtabstop
  if sw == 0 then
    sw = tabstop
  end
  if sts < 0 then
    sts = sw
  end
  return sw == tabstop and (sts == 0 or sts == tabstop)
end

local function is_excluded(bufnr)
  local bo = vim.bo[bufnr]
  return vim.list_contains(opt.exclude_filetype, bo.filetype)
    or vim.list_contains(opt.exclude_buftype, bo.buftype)
end

local lcs_cache = {}
local lcs_failed = {}
local lcs_pending = {}

local function parse_lcs(str)
  local t = {}
  for item in vim.gsplit(str, ',', { plain = true }) do
    local k, v = item:match('^([^:]+):(.*)$')
    if k then
      t[k] = v
    end
  end
  return t
end

local function is_ours(value)
  return value:find('leadmultispace:' .. opt.char, 1, true) ~= nil
    or value:find('leadtab:' .. opt.char, 1, true) ~= nil
end

-- 窗口 local 值为空、是我们设的、或者和全局值相同（`:set listchars=...` 会顺手把当前窗口
-- 的 local 值也设成一样）时可以覆盖；用户明确 `setlocal` 过的不碰，那个窗口走 extmark。
local function can_touch(cur)
  return cur == '' or is_ours(cur) or cur == vim.go.listchars
end

local function lcs_for(bufnr)
  local mode, step
  if vim.bo[bufnr].expandtab then
    mode, step = 'space', get_step(bufnr)
  elseif is_pure_tab(bufnr) then
    mode, step = 'tab', 0
  else
    return ''
  end

  local global = vim.go.listchars
  local key = mode .. step .. '\0' .. global
  local value = lcs_cache[key]
  if value then
    return value
  end

  local lcs = parse_lcs(global)
  lcs.leadmultispace, lcs.leadtab = nil, nil
  if mode == 'space' then
    lcs.leadmultispace = opt.char .. (' '):rep(step - 1)
  else
    lcs.tab = lcs.tab or '  '
    lcs.leadtab = opt.char .. ' '
  end

  local keys = vim.tbl_keys(lcs)
  table.sort(keys)
  local parts = {}
  for _, k in ipairs(keys) do
    parts[#parts + 1] = k .. ':' .. lcs[k]
  end
  value = table.concat(parts, ',')
  lcs_cache[key] = value
  return value
end

local function local_lcs(winid)
  return api.nvim_get_option_value('listchars', { scope = 'local', win = winid })
end

local function apply_lcs(winid, bufnr, want)
  if lcs_failed[want] then
    return false
  end
  if not api.nvim_win_is_valid(winid) or api.nvim_win_get_buf(winid) ~= bufnr then
    return false
  end
  local cur = local_lcs(winid)
  if cur == want or not can_touch(cur) then
    return false
  end
  local ok, err =
    pcall(api.nvim_set_option_value, 'listchars', want, { scope = 'local', win = winid })
  if not ok then
    lcs_failed[want] = true
    vim.notify_once(
      ('indent: set listchars failed, falling back to extmarks: %s'):format(err),
      vim.log.levels.WARN
    )
    return false
  end
  if local_lcs(winid) ~= want then
    lcs_failed[want] = true
    return false
  end
  return true
end

local function schedule_lcs(winid, bufnr, want, cur)
  if cur == want or lcs_failed[want] or lcs_pending[winid] == want or not can_touch(cur) then
    return
  end
  lcs_pending[winid] = want
  vim.schedule(function()
    lcs_pending[winid] = nil
    apply_lcs(winid, bufnr, want)
  end)
end

local function sync_win(winid, bufnr)
  local want = (opt.enabled and not is_excluded(bufnr)) and lcs_for(bufnr) or ''
  return apply_lcs(winid, bufnr, want)
end

local BLANK, FLAG, IMASK = 0x8000, 0x4000, 0x3FFF
local BLANK_MARK = BLANK
local UP, DOWN = -1, 1

local function pack(blank, flag, indent)
  return bit.bor(blank and BLANK or 0, flag and FLAG or 0, bit.band(indent, IMASK))
end

local function get_line(c, row)
  return ffi.string(ml_get_buf(c.handle, row + 1))
end

local function is_blank(text)
  return text:find('^[ \t]*$') ~= nil
end

local function lead_needs_extmark(text, expandtab)
  return text:find(expandtab and '^[ \t]*\t' or '^[ \t]* ') ~= nil
end

local function pack_line(c, text, row)
  return pack(false, lead_needs_extmark(text, c.expandtab), get_indent_buf(c.handle, row + 1))
end

--- @param c table
--- @param row integer 0-indexed
--- @param direction integer UP(-1) or DOWN(1)
--- @return integer
local function search_nearest(c, row, direction)
  local r = row
  while r >= 0 and r < c.count do
    local packed = c.snapshot[r]
    if packed == nil then
      local text = get_line(c, r)
      packed = is_blank(text) and BLANK_MARK or pack_line(c, text, r)
      c.snapshot[r] = packed
    end
    if bit.band(packed, BLANK) == 0 then
      return bit.band(packed, IMASK)
    end
    r = r + direction
  end
  return 0
end

local function blank_indent(c, row)
  local node
  if c.ts then
    local ok, n =
      pcall(ts.get_node, { bufnr = c.bufnr, pos = { row, 0 }, ignore_injections = true })
    if ok and n then
      node = n
      if vim.list_contains(opt.ts_exclude_nodetype, node:type()) then
        c.snapshot[row] = pack(true, true, 0)
        return
      end
    end
  end

  local up = search_nearest(c, row - 1, UP)
  local down = search_nearest(c, row + 1, DOWN)
  local indent
  if node and node:parent() == nil then
    indent = down
  else
    indent = math.max(up, down)
  end
  c.snapshot[row] = pack(true, true, indent)
end

local function row_info(c, row)
  local packed = c.snapshot[row]
  if packed == BLANK_MARK then
    blank_indent(c, row)
    return c.snapshot[row]
  end
  if packed == nil then
    local text = get_line(c, row)
    if is_blank(text) then
      blank_indent(c, row)
      return c.snapshot[row]
    end
    packed = pack_line(c, text, row)
    c.snapshot[row] = packed
  end
  return packed
end

------------------------------------------------------------------------
-- decoration provider
------------------------------------------------------------------------

local ctx = {}

local function build_cache(winid, bufnr)
  local bo = vim.bo[bufnr]
  local expandtab = bo.expandtab
  local tsactive = ts.highlighter.active[bufnr] ~= nil

  local sig = table.concat({
    api.nvim_buf_get_changedtick(bufnr),
    bo.tabstop,
    expandtab and 1 or 0,
    is_pure_tab(bufnr) and 1 or 0,
    tsactive and 1 or 0,
  }, ':')

  local c = ctx[winid]
  if not c or c.bufnr ~= bufnr or c.sig ~= sig then
    c = { bufnr = bufnr, sig = sig, snapshot = {} }
    ctx[winid] = c
  end
  c.handle = buf_handle(bufnr)
  c.count = api.nvim_buf_line_count(bufnr)
  c.step = get_step(bufnr)
  c.expandtab = expandtab
  c.ts = tsactive

  local want = lcs_for(bufnr)
  local cur = local_lcs(winid)
  schedule_lcs(winid, bufnr, want, cur)
  c.use_lcs = want ~= '' and cur == want and api.nvim_get_option_value('list', { win = winid })

  local curwin = api.nvim_get_current_win()

  c.leftcol = 0
  if not api.nvim_get_option_value('wrap', { win = winid }) then
    if winid == curwin then
      c.leftcol = vim.fn.winsaveview().leftcol
    else
      local ok, view = pcall(api.nvim_win_call, winid, vim.fn.winsaveview)
      if ok then
        c.leftcol = view.leftcol
      end
    end
  end

  c.insert = api.nvim_get_mode().mode:sub(1, 1) == 'i'
  c.currow, c.curcol = -1, -1
  if c.insert and opt.avoid_cursor_in_insert and winid == curwin then
    local pos = api.nvim_win_get_cursor(winid)
    c.currow = pos[1] - 1
    c.curcol = vim.fn.strdisplaywidth(get_line(c, c.currow):sub(1, pos[2]))
  end
end

api.nvim_set_decoration_provider(ns, {
  on_win = function(_, winid, bufnr)
    if not opt.enabled or is_excluded(bufnr) then
      schedule_lcs(winid, bufnr, '', local_lcs(winid))
      ctx[winid] = nil
      return false
    end
    build_cache(winid, bufnr)
  end,
  on_line = function(_, winid, bufnr, row)
    local c = ctx[winid]
    if not c or c.bufnr ~= bufnr then
      return
    end

    local packed = row_info(c, row)
    local blank = bit.band(packed, BLANK) ~= 0
    if not blank and c.use_lcs and bit.band(packed, FLAG) == 0 then
      return
    end

    local indent = bit.band(packed, IMASK)
    if indent <= 0 then
      return
    end

    local step = c.step
    for level = opt.minlevel, math.ceil(indent / step) do
      local col = (level - 1) * step
      if
        col >= c.leftcol and not (c.insert and not blank and row == c.currow and col == c.curcol)
      then
        api.nvim_buf_set_extmark(bufnr, ns, row, 0, {
          virt_text = { { opt.char, opt.hl } },
          virt_text_pos = 'overlay',
          virt_text_win_col = col - c.leftcol,
          hl_mode = 'combine',
          ephemeral = true,
        })
      end
    end
  end,
})

api.nvim_create_autocmd({ 'BufWinEnter', 'BufEnter' }, {
  group = augroup,
  callback = function(args)
    sync_win(api.nvim_get_current_win(), args.buf)
  end,
})

api.nvim_create_autocmd('OptionSet', {
  group = augroup,
  pattern = { 'shiftwidth', 'tabstop', 'expandtab', 'softtabstop' },
  callback = function(args)
    for _, winid in ipairs(vim.fn.win_findbuf(args.buf)) do
      if not sync_win(winid, args.buf) then
        -- listchars 没变也要重画：空行 / 混排的 extmark 依赖 step
        pcall(api.nvim__redraw, { win = winid, valid = false })
      end
    end
  end,
})

api.nvim_create_autocmd('WinClosed', {
  group = augroup,
  callback = function(args)
    local winid = tonumber(args.match)
    ctx[winid] = nil
    lcs_pending[winid] = nil
  end,
})

if vim.v.vim_did_enter == 1 then
  for _, winid in ipairs(api.nvim_list_wins()) do
    sync_win(winid, api.nvim_win_get_buf(winid))
  end
end
