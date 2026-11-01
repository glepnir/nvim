local api, fn, treesitter = vim.api, vim.fn, vim.treesitter
local uv = vim.uv or vim.loop
local mapset = vim.keymap.set

local FORWARD, BACKWARD = 1, 2
local FLUSH_MS = 100 -- flush parsed results to the list (and advance the animation) this often
local BAR_WIDTH = 15
local MAX_RESULTS = 50000 -- stop the search after this many matches (math.huge: no limit)
local RG_MAX_COLUMNS = 500 -- rg only: rg shortens longer lines itself (minified files); nil: off
local PREVIEW_MAX_SIZE = 2 * 1024 * 1024 -- larger files: read only up to the match (+ margin)
local PREVIEW_MARGIN = 1000
local PREVIEW_HL_MAX_SIZE = 512 * 1024 -- larger files are previewed without highlighting
local PREVIEW_DEBOUNCE_MS = 30 -- loading another file waits until the cursor settles
local TS_HIGHLIGHT = true -- highlight the match text with the file's treesitter parser

local HEADER = '▾ ' -- prefix of the file header rows
-- Plain byte compare instead of =~#, so no regex is compiled for every line.
local FOLDEXPR = ("getline(v:lnum)[:%d]==#'%s'?'>1':(getline(1)[:%d]==#'%s'?'1':'0')"):format(
  #HEADER - 1,
  HEADER,
  #HEADER - 1,
  HEADER
)

local DEFAULT_STL = "%t%{exists('w:quickfix_title')? ' '.w:quickfix_title : ''} %=%-15(%l,%c%V%) %P"

local state = {
  preview = {
    enabled = false,
    group = nil, -- augroup of the preview's autocmds
    win = nil,
    buf = nil, -- scratch buffer: previewed files are copied here, never loaded for real
    file = nil, -- path currently shown
    tick = nil, -- changedtick of the source buffer when copied (-1: read from disk)
    truncated = false,
    nlines = 0,
    hl_key = nil, -- "lang|ft" currently highlighting the scratch buffer
    timer = nil, -- debounce timer for loading another file
  },
  job = nil, -- { cancel = fn } of the running search
}

-- qf/loclist id -> { is_quick, owner, title, count, done, cancelled, limited, tick,
--                   display, files, hl, langs }
-- display[i] is the rendered text of item i, so quickfixtextfunc is a plain slice.
-- files[i] is its file (for the parser), hl[i] its cached highlight spans,
-- langs[file] the file's treesitter language (false: none).
local lists = {}

-- ── helpers ────────────────────────────────────────────────────────────────

local function esc_stl(s)
  return (s:gsub('%%', '%%%%'))
end

-- win_gettype() is far cheaper than getwininfo(), which builds a dict with
-- all of the window's variables; this runs on every statusline redraw.
local function is_loclist(win)
  return fn.win_gettype(win) == 'loclist'
end

local function has_part(parts, pat)
  for _, part in ipairs(parts) do
    if part:find(pat) then
      return true
    end
  end
  return false
end

---Split a command line like a shell would, but only as far as we need:
---'single' and "double" quotes group words; a backslash escapes only a
---space, a quote or another backslash (so regex escapes like \b survive).
local function split_args(s)
  local out, cur, quote, escaped, has = {}, {}, nil, false, false
  for c in s:gmatch('.') do
    if escaped then
      if not (c:match('%s') or c == '"' or c == "'" or c == '\\') then
        cur[#cur + 1] = '\\'
      end
      cur[#cur + 1], escaped, has = c, false, true
    elseif c == '\\' and quote ~= "'" then
      escaped = true
    elseif quote then
      if c == quote then
        quote = nil
      else
        cur[#cur + 1] = c
      end
    elseif c == '"' or c == "'" then
      quote, has = c, true
    elseif c:match('%s') then
      if has then
        out[#out + 1], cur, has = table.concat(cur), {}, false
      end
    else
      cur[#cur + 1], has = c, true
    end
  end
  if escaped then
    cur[#cur + 1], has = '\\', true
  end
  if has then
    out[#out + 1] = table.concat(cur)
  end
  return out
end

---Get entry `idx` of the list shown in `win`. With 'idx', getqflist() returns
---only that entry, so this stays cheap however long the list is.
local function list_item(win, idx, loc)
  local what = { idx = idx, items = 0 }
  local res = loc and fn.getloclist(win, what) or fn.getqflist(what)
  return res.items and res.items[1] or nil
end

---Forget lists that no longer exist (pushed off the stack, freed, owner closed).
local function prune_lists()
  for id, l in pairs(lists) do
    local alive
    if l.is_quick then
      alive = fn.getqflist({ id = id }).id == id
    else
      alive = api.nvim_win_is_valid(l.owner) and fn.getloclist(l.owner, { id = id }).id == id
    end
    if not alive then
      lists[id] = nil
    end
  end
end

-- ── quickfixtextfunc / statusline / foldtext ──────────────────────────────

local function qf_text(info)
  local l = lists[info.id]
  if not l then
    return {} -- not ours (or forgotten): Neovim falls back to the default format
  end
  return vim.list_slice(l.display, info.start_idx, info.end_idx)
end

---Statusline of every quickfix/location list window. Looks up the list the
---window currently shows, so :colder / :cnewer / other lists get the default.
function _G.__grep_qf_statusline()
  local win = vim.g.statusline_winid
  local id = is_loclist(win) and fn.getloclist(win, { id = 0 }).id or fn.getqflist({ id = 0 }).id
  local l = lists[id]
  if not l then
    return DEFAULT_STL
  end
  local bar
  if l.done then
    bar = ('●'):rep(BAR_WIDTH)
  else
    local pos = l.tick % BAR_WIDTH + 1
    bar = ('○'):rep(pos - 1) .. '●' .. ('○'):rep(BAR_WIDTH - pos)
  end
  local label = l.limited and 'Limited'
    or l.cancelled and 'Cancelled'
    or l.done and 'Done'
    or 'Searching'
  return string.format(
    ' %s [%s] %d matches  %%<%s%%=%%-15(%%l,%%c%%V%%) %%P',
    label,
    bar,
    l.count,
    esc_stl(l.title)
  )
end

---Folded file header: "▸ path  (N)", N = number of matches in the fold.
function _G.__grep_qf_foldtext()
  local fs, fe = vim.v.foldstart, vim.v.foldend
  local name = fn.getline(fs)
  if name:sub(1, #HEADER) == HEADER then
    name = name:sub(#HEADER + 1)
  end
  return string.format('▸ %s  (%d)', name, fe - fs)
end

---Redraw only the given window's statusline. `redrawstatus!` would re-evaluate
---every statusline in every window (lualine & co.) ten times a second.
local function redraw_status(win)
  if not (win and win ~= 0 and api.nvim_win_is_valid(win)) then
    return
  end
  if not pcall(api.nvim__redraw, { win = win, statusline = true, flush = true }) then
    pcall(api.nvim_win_call, win, function()
      vim.cmd('redrawstatus')
    end)
  end
end

-- ── preview ────────────────────────────────────────────────────────────────

local function close_preview()
  local p = state.preview
  p.enabled = false
  if p.timer then
    p.timer:stop()
  end
  if p.group then
    pcall(api.nvim_del_augroup_by_id, p.group) -- first, so WinClosed below doesn't re-enter
    p.group = nil
  end
  if p.win and api.nvim_win_is_valid(p.win) then
    pcall(api.nvim_win_close, p.win, true) -- bufhidden=wipe also removes the scratch buffer
  end
  if p.buf and api.nvim_buf_is_valid(p.buf) then
    pcall(api.nvim_buf_delete, p.buf, { force = true })
  end
  p.win, p.buf, p.file, p.tick, p.hl_key = nil, nil, nil, nil, nil
end

local function create_preview_window(buf)
  local p = state.preview
  local qf_win = api.nvim_get_current_win()
  local qf_width = api.nvim_win_get_width(qf_win)
  local qf_position = api.nvim_win_get_position(qf_win)

  local height = math.floor(vim.o.lines * 0.6)
  local row = qf_position[1] - height - 3
  if row < 0 then
    row = 0
    height = math.max(qf_position[1] - 1, 1)
  end

  p.win = api.nvim_open_win(buf, false, {
    style = 'minimal',
    relative = 'editor',
    row = row,
    col = qf_position[2],
    width = qf_width,
    height = height,
    focusable = false,
  })
  vim.wo[p.win].cursorline = true -- marks the matched line
  vim.wo[p.win].wrap = false

  -- Closed by any other means: leave preview mode too.
  api.nvim_create_autocmd('WinClosed', {
    group = p.group,
    pattern = tostring(p.win),
    once = true,
    callback = function()
      vim.schedule(close_preview)
    end,
  })
end

---Copy the file into the scratch buffer (the real buffer is never loaded, so
---no BufRead / FileType / LSP attach / swap prompts) and highlight it.
local function load_preview(name, bufnr, lnum)
  local p = state.preview
  local same_file = p.file == name
  local loaded = api.nvim_buf_is_loaded(bufnr)
  local lines, size, truncated = nil, 0, false
  if loaded then
    lines = api.nvim_buf_get_lines(bufnr, 0, -1, false)
    size = api.nvim_buf_get_offset(bufnr, #lines)
  else
    size = fn.getfsize(name)
    local ok, res = false, nil
    if size > PREVIEW_MAX_SIZE then
      ok, res = pcall(fn.readfile, name, '', lnum + PREVIEW_MARGIN)
      truncated = true
    elseif size >= 0 then
      ok, res = pcall(fn.readfile, name)
    end
    lines = ok and res or { '[cannot read ' .. name .. ']' }
    for i, line in ipairs(lines) do -- readfile turns NUL into NL, which set_lines rejects
      if line:find('\n', 1, true) then
        lines[i] = line:gsub('\n', '\0')
      end
    end
  end

  vim.bo[p.buf].modifiable = true
  api.nvim_buf_set_lines(p.buf, 0, -1, false, lines)
  vim.bo[p.buf].modifiable = false
  p.file, p.truncated, p.nlines = name, truncated, #lines
  p.tick = loaded and api.nvim_buf_get_changedtick(bufnr) or -1

  -- Same file re-read (edited, or a truncated read extended): highlighting still fits.
  if same_file then
    return
  end

  -- Highlight without setting 'filetype' (that would run ftplugins / attach LSP).
  -- Big files get none: parsing them costs more than the preview is worth.
  local ft, lang
  if size <= PREVIEW_HL_MAX_SIZE then
    local ok_ft, res = pcall(vim.filetype.match, { buf = p.buf, filename = name })
    ft = ok_ft and res or nil
    lang = ft and treesitter.language.get_lang(ft) or nil
  end
  local key = (lang or '') .. '|' .. (ft or '')
  if key ~= p.hl_key then
    pcall(treesitter.stop, p.buf)
    vim.bo[p.buf].syntax = ''
    if not (lang and pcall(treesitter.start, p.buf, lang)) then
      vim.bo[p.buf].syntax = ft or '' -- no parser: regex syntax
    end
    p.hl_key = key
  end
end

local update_preview -- forward declaration: the debounce timer calls it

local function defer_preview()
  local p = state.preview
  p.timer = p.timer or uv.new_timer()
  p.timer:stop()
  p.timer:start(
    PREVIEW_DEBOUNCE_MS,
    0,
    vim.schedule_wrap(function()
      update_preview(true)
    end)
  )
end

---@param now boolean load another file right away instead of debouncing
update_preview = function(now)
  local p = state.preview
  if not p.enabled then
    return
  end
  local win = api.nvim_get_current_win()
  local wtype = fn.win_gettype(win)
  if wtype ~= 'quickfix' and wtype ~= 'loclist' then
    return
  end

  local item = list_item(win, api.nvim_win_get_cursor(win)[1], wtype == 'loclist')
  -- NOTE: bufnr == 0 is truthy in Lua, must compare explicitly
  if not item or not item.bufnr or item.bufnr == 0 then
    return
  end
  local name = api.nvim_buf_get_name(item.bufnr)
  if name == '' then
    return
  end

  if not (p.buf and api.nvim_buf_is_valid(p.buf)) then
    p.buf = api.nvim_create_buf(false, true)
    vim.bo[p.buf].bufhidden = 'wipe'
    p.file, p.tick, p.hl_key = nil, nil, nil
  end

  -- Header rows (and some invalid entries) have lnum 0: show the top of the file.
  local lnum = math.max(item.lnum or 1, 1)
  local loaded = api.nvim_buf_is_loaded(item.bufnr)
  local tick = loaded and api.nvim_buf_get_changedtick(item.bufnr) or -1
  if p.file == name and p.tick == -1 and loaded and not vim.bo[item.bufnr].modified then
    -- Just loaded from the same file on disk (e.g. by :cnext): the copy is
    -- still accurate, no need to copy and re-highlight it again.
    p.tick = tick
  end
  local stale = p.file ~= name or p.tick ~= tick or (p.truncated and lnum > p.nlines)

  -- Reading and highlighting another file is the slow part: while the cursor
  -- races across files (holding j), wait until it settles.
  if stale and not now then
    defer_preview()
    return
  end
  if p.timer then
    p.timer:stop()
  end

  if not (p.win and api.nvim_win_is_valid(p.win)) then
    create_preview_window(p.buf)
    if not (p.win and api.nvim_win_is_valid(p.win)) then
      return
    end
  end
  if stale then
    load_preview(name, item.bufnr, lnum)
  end

  lnum = math.min(lnum, math.max(p.nlines, 1))
  local col = math.max((item.col or 1) - 1, 0)
  pcall(api.nvim_win_set_cursor, p.win, { lnum, col })
  api.nvim_win_call(p.win, function()
    vim.cmd('normal! zz')
  end)
end

local function toggle_preview(buf)
  local p = state.preview
  if p.enabled then
    close_preview()
    return
  end
  p.enabled = true
  p.group = api.nvim_create_augroup('grep.preview', { clear = true })
  api.nvim_create_autocmd('CursorMoved', {
    group = p.group,
    buffer = buf,
    callback = function()
      update_preview(false)
    end,
  })
  -- :cclose / :lclose / switching the window to another buffer: close the float too.
  api.nvim_create_autocmd('BufWinLeave', {
    group = p.group,
    buffer = buf,
    callback = function()
      vim.schedule(close_preview) -- can't change the window layout inside this event
    end,
  })
  update_preview(true)
end

-- ── treesitter highlighting of the match text ─────────────────────────────

-- Each match line is parsed on its own with its file's parser, lazily and only
-- for rows that are actually drawn (decoration provider), then cached per row,
-- so the cost doesn't depend on the size of the list.
local ns = api.nvim_create_namespace('grep.qf')
local qf_bufs = {} -- list buffers we've set up
local win_list = {} -- winid -> list info, for the current redraw only
local queries = {} -- lang -> highlights query | false
local hl_ids = {} -- '@capture.lang' -> highlight id

---Treesitter language of file `f` if it has a highlights query, else false.
local function file_lang(l, f)
  local lang = l.langs[f]
  if lang ~= nil then
    return lang
  end
  lang = false
  local ok, ft = pcall(vim.filetype.match, { filename = f })
  local name = ok and ft and treesitter.language.get_lang(ft)
  if name then
    if queries[name] == nil then
      local okq, q = pcall(treesitter.query.get, name, 'highlights')
      queries[name] = okq and q or false
    end
    if queries[name] then
      lang = name
    end
  end
  l.langs[f] = lang
  return lang
end

---Highlight spans of one line as a flat list: start, end, hl id, priority, ...
---The line is parsed without its surrounding code, so one from the middle of
---a multi-line comment or string can come out wrong.
local function line_spans(text, lang)
  local spans = {}
  local ok, parser = pcall(treesitter.get_string_parser, text, lang)
  if not ok then
    return spans
  end
  local okp, trees = pcall(parser.parse, parser)
  local tree = okp and trees and trees[1]
  if not tree then
    return spans
  end
  local query = queries[lang]
  for id, node, metadata in query:iter_captures(tree:root(), text, 0, 1) do
    local name = query.captures[id]
    -- 95 = '_': private captures, like the treesitter highlighter skips them
    if name:byte(1) ~= 95 and name ~= 'spell' and name ~= 'nospell' and name ~= 'conceal' then
      local key = '@' .. name .. '.' .. lang
      local hl = hl_ids[key]
      if not hl then
        hl = api.nvim_get_hl_id_by_name(key)
        hl_ids[key] = hl
      end
      local sr, sc, er, ec = node:range()
      if er > sr then
        ec = #text
      end
      if ec > sc then
        local n = #spans
        spans[n + 1], spans[n + 2] = sc, ec
        spans[n + 3], spans[n + 4] = hl, tonumber(metadata.priority) or 100
      end
    end
  end
  return spans
end

---Draw one row: a GrepText base under the whole text (in our format the qf
---syntax paints entire lines as qfFileName) and the treesitter spans on top.
local function draw_row(l, bufnr, row)
  local i = row + 1
  local spans = l.hl[i]
  if spans == nil then
    spans = false
    local line = l.display[i]
    local p = line and line:find('│ ', 1, true) -- header rows have none
    if p then
      local f = l.files[i]
      local lang = TS_HIGHLIGHT and f and file_lang(l, f)
      spans = lang and line_spans(line:sub(p + 4), lang) or {} -- '│' is 3 bytes + a space
      spans.col, spans.len = p + 3, #line
    end
    l.hl[i] = spans
  end
  if not spans then
    return
  end
  local col = spans.col
  api.nvim_buf_set_extmark(bufnr, ns, row, col, {
    end_col = spans.len,
    hl_group = 'GrepText',
    priority = 99, -- below treesitter's 100
    ephemeral = true,
    strict = false,
  })
  for k = 1, #spans, 4 do
    api.nvim_buf_set_extmark(bufnr, ns, row, col + spans[k], {
      end_col = col + spans[k + 1],
      hl_group = spans[k + 2],
      priority = spans[k + 3],
      ephemeral = true,
      strict = false,
    })
  end
end

-- ── list window setup ─────────────────────────────────────────────────────

local function define_hl()
  -- fg only: a background would cover CursorLine / QuickFixLine
  local function fg_only(name, src)
    local h = api.nvim_get_hl(0, { name = src, link = false })
    api.nvim_set_hl(0, name, { fg = h.fg, ctermfg = h.ctermfg, bold = h.bold, default = true })
  end
  fg_only('GrepFileName', 'Directory')
  fg_only('GrepLineNr', 'LineNr')
  fg_only('GrepSeparator', 'Delimiter')
  fg_only('GrepText', 'Normal')
end

local function move(dir)
  return function()
    local loc = is_loclist(api.nvim_get_current_win())
    local cmd = dir == FORWARD and (loc and 'lnext' or 'cnext') or (loc and 'lprev' or 'cprev')
    local ok, err = pcall(vim.cmd, vim.v.count1 .. cmd) -- header rows are invalid: skipped
    if not ok then
      vim.notify((tostring(err):gsub('^Vim:', '')), vim.log.levels.WARN)
      return
    end
    -- :cnext from the list window jumps into the editing window; come back so
    -- these buffer-local maps keep working (the list cursor follows the entry).
    vim.cmd('wincmd p')
    update_preview(true)
  end
end

---Buffer-local maps, once per list buffer. Whether it's a quickfix or a
---location list is decided at key press, so the same maps serve both.
local function setup_buf(buf)
  qf_bufs[buf] = true
  if vim.b[buf].grep_qf_maps then
    return
  end
  vim.b[buf].grep_qf_maps = true

  mapset('n', 'q', function()
    close_preview()
    vim.cmd(is_loclist(api.nvim_get_current_win()) and 'lclose' or 'cclose')
  end, { buffer = buf, desc = 'Close list' })
  mapset('n', '<Esc>', close_preview, { buffer = buf, desc = 'Close preview' })
  mapset('n', '<C-n>', move(FORWARD), { buffer = buf, desc = 'Next entry' })
  mapset('n', '<C-p>', move(BACKWARD), { buffer = buf, desc = 'Previous entry' })
  mapset('n', 'p', function()
    toggle_preview(buf)
  end, { buffer = buf, desc = 'Toggle preview' })
  mapset('n', '<Tab>', 'za', { buffer = buf, desc = 'Toggle file fold' })
  mapset('n', 'zf', 'zM', { buffer = buf, desc = 'Fold all files' })
  mapset('n', 'zF', 'zR', { buffer = buf, desc = 'Unfold all files' })
end

---Window-local matches, folds + statusline, once per list window. The
---patterns only match our own format, so other lists shown in the window
---are unaffected.
local function setup_win(win)
  if not api.nvim_win_is_valid(win) then
    return
  end
  -- [0] = :setlocal. Plain vim.wo[win] is :set, whose global half is inherited
  -- by windows split off the list (<C-w><CR>), which would then get our
  -- statusline, foldexpr and no line numbers.
  local wo = vim.wo[win][0]
  wo.statusline = '%!v:lua.__grep_qf_statusline()'
  if vim.w[win].grep_qf_matches then
    return
  end
  vim.w[win].grep_qf_matches = true
  wo.wrap = false
  wo.number = false
  wo.relativenumber = false
  wo.signcolumn = 'no'

  -- Fold each file's matches under its header. Only lists in our format
  -- (first line is a header) get folds; anything else gets level 0.
  wo.foldmethod = 'expr'
  wo.foldexpr = FOLDEXPR
  wo.foldtext = 'v:lua.__grep_qf_foldtext()'
  wo.foldlevel = 99 -- start (and keep streaming results) unfolded
  wo.foldenable = true
  wo.foldcolumn = '0'
  wo.fillchars = 'fold: '

  fn.matchadd('GrepFileName', '^▾ \\zs.*', 12, -1, { window = win })
  fn.matchadd('GrepLineNr', '^\\s\\+\\d\\+:\\d\\+', 20, -1, { window = win })
  fn.matchadd('GrepSeparator', '│', 15, -1, { window = win })
  -- The text itself is colored by the decoration provider (draw_row): a
  -- matchadd() there would win over every extmark and hide treesitter colors.
end

-- ── search ─────────────────────────────────────────────────────────────────

---@param is_quick boolean quickfix list (true) or location list (false)
---@param args string raw command arguments: pattern [paths...]
---@param regex boolean use a regex instead of --fixed-strings
local function grep(is_quick, args, regex)
  local tokens = split_args(args)
  if #tokens == 0 then
    return
  end
  local pattern = table.remove(tokens, 1)
  local paths = {}
  for _, t in ipairs(tokens) do
    local ok, expanded = pcall(fn.expandcmd, t) -- %, #, ~, $VAR like :grep
    paths[#paths + 1] = ok and expanded or t
  end

  -- Build the command. Expand a '$*' placeholder in 'grepprg' if present,
  -- otherwise append. `-e` keeps patterns starting with '-' from being options.
  local prg = split_args(vim.o.grepprg)
  local cmd, placed = {}, false
  local function add_query()
    if not regex then
      cmd[#cmd + 1] = '--fixed-strings'
    end
    cmd[#cmd + 1] = '-e'
    cmd[#cmd + 1] = pattern
    vim.list_extend(cmd, paths)
  end
  for _, part in ipairs(prg) do
    if part == '$*' then
      placed = true
      add_query()
    else
      cmd[#cmd + 1] = part
    end
  end
  if not placed then
    add_query()
  end

  -- Decide the output format once instead of trying two patterns per line.
  -- Guessing per line also misreads "file:12:30:00 text" from grep -n as a column.
  local has_col = has_part(prg, '^%-%-vimgrep$') or has_part(prg, '^%-%-column$')

  -- Minified files produce megabyte-long lines that would be parsed, stored
  -- twice and rendered; let rg cut them down before they reach Lua.
  if
    RG_MAX_COLUMNS
    and cmd[1]
    and fn.fnamemodify(cmd[1], ':t:r') == 'rg'
    and not has_part(prg, '^%-M')
    and not has_part(prg, '^%-%-max%-columns')
  then
    table.insert(cmd, 2, '--max-columns=' .. RG_MAX_COLUMNS)
    table.insert(cmd, 3, '--max-columns-preview')
  end

  -- Only one search at a time: a new one cancels the previous.
  if state.job then
    state.job.cancel()
    state.job = nil
  end
  prune_lists()

  -- Location lists are per-window: remember whose list we own, otherwise
  -- appends go to whatever window happens to be focused later.
  local owner = api.nvim_get_current_win()
  local function setlist(action, what)
    if is_quick then
      return fn.setqflist({}, action, what)
    end
    return fn.setloclist(owner, {}, action, what)
  end
  local function getlist(what)
    if is_quick then
      return fn.getqflist(what)
    end
    return fn.getloclist(owner, what)
  end

  -- Create the (empty) list up front: its id is known before the first
  -- append, so display[] is always filled before quickfixtextfunc runs.
  local title = (is_quick and 'GREP' or 'Grep') .. (regex and '! ' or ' ') .. args
  setlist(' ', { title = title, items = {}, quickfixtextfunc = qf_text })
  local id = getlist({ id = 0 }).id
  local info = {
    is_quick = is_quick,
    owner = owner,
    title = title,
    count = 0,
    done = false,
    cancelled = false,
    limited = false,
    tick = 0,
    display = {},
    files = {},
    hl = {},
    langs = {},
  }
  lists[id] = info

  -- Paths from the tool are relative to this directory.
  local cwd = fn.getcwd()
  local sep = package.config:sub(1, 1)

  -- Filled by the stdout callback (fast context: pure Lua only), drained by flush().
  local chunk, chunk_text, chunk_file = {}, {}, {}
  local pending = '' -- carries an incomplete trailing line between stdout chunks
  local seen_files = {}
  local total = 0 -- real matches parsed so far
  local limited = false -- MAX_RESULTS reached: the process was killed
  local eof, exit_obj = false, nil
  local finished, opened = false, false
  local timer = uv.new_timer()
  local handle, job

  local function parse_line(line)
    -- grep/rg --vimgrep format: filename:lnum:col:text (col only with --vimgrep / --column)
    local f, l, c, text
    if has_col then
      f, l, c, text = line:match('^(.-):(%d+):(%d+):(.*)')
    else
      f, l, text = line:match('^(.-):(%d+):(.*)')
    end
    if not f or f == '' then
      return -- warnings, binary-file notices, ...: not a match
    end
    if total >= MAX_RESULTS then
      limited, info.limited = true, true
      if handle then
        pcall(handle.kill, handle, 15)
      end
      return
    end
    total = total + 1
    if not seen_files[f] then
      seen_files[f] = true
      -- invalid entry: rendered as the file header (fold start), skipped by :cnext / :cdo
      chunk[#chunk + 1] = { filename = f, valid = 0, user_data = 'header' }
      chunk_text[#chunk_text + 1] = HEADER .. f
      chunk_file[#chunk_file + 1] = f
    end
    local lnum, col = tonumber(l), tonumber(c) or 0
    chunk[#chunk + 1] = { filename = f, lnum = lnum, col = col, text = text }
    chunk_text[#chunk_text + 1] = string.format('  %4d:%-3d │ %s', lnum, col, text)
    chunk_file[#chunk_file + 1] = f
  end

  ---setqflist() resolves relative names against the cwd at the time of the
  ---call. If that changed since the search started (:lcd, :tcd, 'autochdir'),
  ---rewrite them; otherwise this costs a single getcwd().
  local function fix_paths(items)
    local now = fn.getcwd()
    if now == cwd then
      return
    end
    local memo = {}
    for _, it in ipairs(items) do
      local f = it.filename
      local r = memo[f]
      if not r then
        local abs = f:sub(1, 1) == '/' or f:find('^%a:[/\\]') ~= nil
        r = abs and f or fn.fnamemodify(cwd .. sep .. f, ':.')
        memo[f] = r
      end
      it.filename = r
    end
  end

  local function stop_timer()
    if not timer:is_closing() then
      timer:stop()
      timer:close()
    end
  end

  local function list_alive()
    if not is_quick and not api.nvim_win_is_valid(owner) then
      return false
    end
    return getlist({ id = id }).id == id
  end

  local function list_win()
    if not is_quick and not api.nvim_win_is_valid(owner) then
      return nil
    end
    return getlist({ winid = 0 }).winid
  end

  local function cancel()
    if finished then
      return
    end
    finished = true
    info.cancelled, info.done = true, true
    stop_timer()
    if handle then
      pcall(handle.kill, handle, 15)
    end
    if state.job == job then
      state.job = nil
    end
    redraw_status(list_win())
  end

  ---Open the list window. Focus moves into it only if the user is still in
  ---the window the search started from and in Normal mode; otherwise it opens
  ---in the background instead of yanking the cursor away.
  local function open_list()
    opened = true
    local cur = api.nvim_get_current_win()
    local steal = cur == owner and api.nvim_get_mode().mode == 'n'
    local from = is_quick and cur or owner
    pcall(api.nvim_win_call, from, function()
      vim.cmd(is_quick and 'copen' or 'lopen')
    end)
    local lwin = getlist({ winid = 0 }).winid
    if lwin and lwin ~= 0 then
      setup_buf(api.nvim_win_get_buf(lwin))
      setup_win(lwin)
      if steal then
        api.nvim_set_current_win(lwin)
      end
    end
  end

  local function flush()
    if finished then
      return
    end
    if not list_alive() then
      cancel() -- list freed / owner window closed: stop searching
      return
    end
    if #chunk > 0 then
      local items, text, files = chunk, chunk_text, chunk_file
      chunk, chunk_text, chunk_file = {}, {}, {}
      fix_paths(items)
      vim.list_extend(info.files, files)
      vim.list_extend(info.display, text) -- before setlist: it calls qf_text
      setlist('a', { id = id, items = items })
    end
    info.count = total
    if not opened and total > 0 then
      open_list()
    end
    redraw_status(list_win())
  end

  local function finish()
    flush()
    if finished then
      return -- cancelled
    end
    finished = true
    info.done = true
    stop_timer()
    if state.job == job then
      state.job = nil
    end
    redraw_status(list_win())

    -- Exit code 1 just means "no matches" for grep/rg; only >1 is an error
    -- (rg also returns 2 when some files couldn't be read but others matched).
    local code = exit_obj and exit_obj.code or 0
    if limited then
      vim.notify(('Grep: stopped after %d matches'):format(total), vim.log.levels.WARN)
    elseif code > 1 then
      local err = vim.trim(exit_obj.stderr or '')
      vim.notify(
        ('Grep exited with code %d%s'):format(code, err ~= '' and ('\n' .. err) or ''),
        total > 0 and vim.log.levels.WARN or vim.log.levels.ERROR
      )
    elseif total == 0 then
      vim.notify('Grep: no matches for ' .. pattern, vim.log.levels.INFO)
    end
  end

  local function on_stdout(err, data)
    if finished then
      return
    end
    if err then
      vim.schedule(function()
        vim.notify('Grep: ' .. tostring(err), vim.log.levels.ERROR)
        cancel()
      end)
      return
    end
    if data then
      if limited then
        return -- process is being killed: drop what's still in the pipe
      end
      -- stdout arrives in arbitrary chunks: the last line may be cut in half,
      -- so only consume lines that end with '\n' and keep the rest.
      -- find/sub instead of vim.split: no temporary table per chunk.
      local s = pending == '' and data or pending .. data
      local pos = 1
      while not limited do
        local nl = s:find('\n', pos, true)
        if not nl then
          break
        end
        if nl > pos then
          parse_line(s:sub(pos, nl - 1))
        end
        pos = nl + 1
      end
      pending = limited and '' or s:sub(pos)
      return
    end
    if pending ~= '' and not limited then
      parse_line(pending) -- final line without a trailing newline
    end
    pending = ''
    eof = true
    if exit_obj then
      vim.schedule(finish)
    end
  end

  local function on_exit(obj)
    exit_obj = obj
    if eof and not finished then -- stdout may close before or after the exit
      vim.schedule(finish)
    end
  end

  local ok, res = pcall(vim.system, cmd, { text = true, cwd = cwd, stdout = on_stdout }, on_exit)
  if not ok then
    finished = true
    info.done, info.cancelled = true, true
    stop_timer()
    vim.notify('Grep: failed to run ' .. cmd[1] .. ': ' .. tostring(res), vim.log.levels.ERROR)
    return
  end
  handle = res
  job = { cancel = cancel }
  state.job = job

  timer:start(
    FLUSH_MS,
    FLUSH_MS,
    vim.schedule_wrap(function()
      if not finished then
        info.tick = info.tick + 1
        flush()
      end
    end)
  )
end

-- ── setup ──────────────────────────────────────────────────────────────────

define_hl()

local group = api.nvim_create_augroup('grep.qf', { clear = true })
api.nvim_create_autocmd('FileType', {
  group = group,
  pattern = 'qf',
  callback = function(a)
    -- deferred: the qf ftplugin runs after us and would overwrite 'statusline'
    vim.schedule(function()
      if not api.nvim_buf_is_valid(a.buf) then
        return
      end
      setup_buf(a.buf)
      for _, win in ipairs(fn.win_findbuf(a.buf)) do
        setup_win(win)
      end
    end)
  end,
})
api.nvim_create_autocmd('ColorScheme', { group = group, callback = define_hl })

api.nvim_set_decoration_provider(ns, {
  -- Called for every window on every redraw: bail out cheaply unless it shows
  -- one of our lists. Only then on_line runs, and only for the drawn rows.
  on_win = function(_, winid, bufnr)
    win_list[winid] = nil
    if not qf_bufs[bufnr] then
      return false
    end
    local id = fn.win_gettype(winid) == 'loclist' and fn.getloclist(winid, { id = 0 }).id
      or fn.getqflist({ id = 0 }).id
    local l = lists[id]
    if not l then
      return false
    end
    win_list[winid] = l
  end,
  on_line = function(_, winid, bufnr, row)
    local l = win_list[winid]
    if l then
      draw_row(l, bufnr, row)
    end
  end,
  on_end = function()
    if next(win_list) then
      win_list = {} -- don't keep closed windows' lists alive
    end
  end,
})

api.nvim_create_user_command('Grep', function(opts)
  grep(false, opts.args, opts.bang)
end, {
  nargs = '+',
  bang = true,
  complete = 'file_in_path',
  desc = 'Search into the location list (! = regex)',
})

api.nvim_create_user_command('GREP', function(opts)
  grep(true, opts.args, opts.bang)
end, {
  nargs = '+',
  bang = true,
  complete = 'file_in_path',
  desc = 'Search into the quickfix list (! = regex)',
})

vim.cmd(
  [[cnoreabbrev <expr> grep (getcmdtype() ==# ':' && getcmdline() ==# 'grep') ? 'Grep' : 'grep']]
)
