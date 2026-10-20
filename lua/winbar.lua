local api, fn, lsp = vim.api, vim.fn, vim.lsp
local uv = vim.uv or vim.loop
local strwidth, floor = api.nvim_strwidth, math.floor

local M = {}

local MOD = (...) or 'winbar'
local EXPR = ("%%{%%v:lua.require'%s'.render()%%}"):format(MOD)
local CLICK = ("@v:lua.require'%s'.click@"):format(MOD)
local METHOD = 'textDocument/documentSymbol'
local NVIM_011 = fn.has('nvim-0.11') == 1
local PATH_SEP = fn.has('win32') == 1 and '[/\\]' or '/'
local MAX_RETRIES = 5 -- empty result / error: retry at most this many times (exponential backoff)
local MAX_DELAY = 2000 -- upper bound (ms) of the adaptive debounce
local SIG_MAX_LINES = 20 -- signature: read at most this many lines below the name

local config = {
  separator = ' › ',
  ellipsis = '…',
  padding = 1,
  max_name_width = 32,
  max_width = 0,
  max_depth = 0,
  path = 'relative',
  modified = '●',
  icons = false,
  kinds = {},
  -- true: WinbarKind<Name> links to the corresponding @lsp.type.<type> (semantic highlight,
  --       follows treesitter/LSP semantic tokens colors; many vscode-style themes leave these unset).
  -- false (default): all link to WinbarSymbol (-> WinBar), matching vscode's default look.
  semantic = false,
  -- Draw a full-width line under the whole winbar, like a separator.
  -- false: off. true = 'underline'; or one of 'undercurl', 'underdouble',
  -- 'underdotted', 'underdashed'. Line color = fg of the WinbarUnderline
  -- highlight group (default: linked to WinSeparator).
  underline = true,
  clickable = true,
  debounce = 200,
  exclude_filetypes = { 'gitcommit', 'gitrebase' },
  -- Only include these LSP symbol kinds in the breadcrumb. nil / {} = all kinds.
  -- Example: { 'Function', 'Method', 'Constructor' } to show only callables.
  -- Filtered-out nodes are skipped entirely; their children are reparented
  -- to the nearest surviving ancestor (or become roots) by range containment.
  include_kinds = { 'Function', 'Method', 'Constructor' },
  -- true: show symbols as `name(params) -> ret`, read from the source starting at
  --       the symbol name, up to the '{' / ';' after the parameter list closes
  --       (multi-line signatures are joined into one line).
  -- false: show the symbol name only.
  signature = true,
  max_signature_width = 80, -- used instead of max_name_width when signature = true
  -- true: color the signature with the buffer's treesitter highlights (like
  -- vscode's sticky scroll). Falls back to WinbarKind<Name> without a parser.
  signature_hl = true,
  -- enabled = function(buf, win) return true end,
}

local KINDS = {
  { 'File', 0xEB60, 'Directory' },
  { 'Module', 0xEA8B, 'Include' },
  { 'Namespace', 0xEA8B, 'Include' },
  { 'Package', 0xEA8B, 'Include' },
  { 'Class', 0xEB5B, 'Type' },
  { 'Method', 0xEA8C, 'Function' },
  { 'Property', 0xEB65, 'Identifier' },
  { 'Field', 0xEB5F, 'Identifier' },
  { 'Constructor', 0xEA8C, 'Special' },
  { 'Enum', 0xEA95, 'Type' },
  { 'Interface', 0xEB61, 'Type' },
  { 'Function', 0xEA8C, 'Function' },
  { 'Variable', 0xEA88, 'Identifier' },
  { 'Constant', 0xEB5D, 'Constant' },
  { 'String', 0xEB8D, 'String' },
  { 'Number', 0xEA90, 'Number' },
  { 'Boolean', 0xEA8F, 'Boolean' },
  { 'Array', 0xEA8A, 'Type' },
  { 'Object', 0xEA8B, 'Type' },
  { 'Key', 0xEA93, 'Identifier' },
  { 'Null', 0xEA8F, 'Constant' },
  { 'EnumMember', 0xEB5E, 'Constant' },
  { 'Struct', 0xEA91, 'Structure' },
  { 'Event', 0xEA86, 'Special' },
  { 'Operator', 0xEB64, 'Operator' },
  { 'TypeParameter', 0xEA92, 'Type' },
}

-- LSP symbol-kind -> LSP semantic-token-type name (lowerCamelCase).
-- Kinds without a matching semantic token type (Array/Object/Key/Null/Constructor, etc.)
-- are left out and fall back to WinbarSymbol even when config.semantic = true.
local LSP_TYPE = {
  Namespace = 'namespace',
  Class = 'class',
  Enum = 'enum',
  Interface = 'interface',
  Struct = 'struct',
  TypeParameter = 'typeParameter',
  Method = 'method',
  Function = 'function',
  Property = 'property',
  Field = 'property',
  Variable = 'variable',
  Constant = 'variable',
  EnumMember = 'enumMember',
  Event = 'event',
  Operator = 'operator',
  Module = 'namespace',
  Package = 'namespace',
}

-- buf -> { ver, tick, enc, symbols, path, timer, fire, cancel, gen, retries, empty, delay }
local bufs = {}
local wins = {} -- win -> { buf, ver, width, mod, row, col, leaf, path, str }
local seq = 0

local sep, sep_w, ell, ell_w, pad, mod, mod_w, kinds, excluded, include_kinds
local NO_KIND -- fallback kind entry, set in prepare()
local fill_hl -- highlight that ends the winbar; the rest of the line is filled with it

local function next_ver()
  seq = seq + 1
  return seq
end

-- ── highlight twins ─────────────────────────────────────────────────────
-- Some groups get a derived "twin" (WinbarHl<Group>) that copies the source
-- group's attributes and fills in missing fg/bg from WinBar:
--   * with config.underline on: every group used in the winbar, plus the
--     underline, so the line runs unbroken under dirs, separators, symbols,
--     icons and the empty fill area alike;
--   * treesitter capture groups (@...): these usually define only fg, so the
--     twin gives them WinBar's background.

local UL_STYLES = { 'underline', 'undercurl', 'underdouble', 'underdotted', 'underdashed' }
local derived = {} -- source group -> twin group name

local function ul_style()
  local u = config.underline
  if u == true then
    return 'underline'
  end
  if type(u) == 'string' and vim.tbl_contains(UL_STYLES, u) then
    return u
  end
end

local function define_twin(src, name)
  local spec = api.nvim_get_hl(0, { name = src, link = false })
  local base = api.nvim_get_hl(0, { name = 'WinBar', link = false })
  spec.fg = spec.fg or base.fg -- groups without colors would otherwise fall back to Normal
  spec.bg = spec.bg or base.bg
  spec.ctermfg = spec.ctermfg or base.ctermfg
  spec.ctermbg = spec.ctermbg or base.ctermbg
  spec.default = nil
  local style = ul_style()
  if style then
    local line = api.nvim_get_hl(0, { name = 'WinbarUnderline', link = false })
    for _, s in ipairs(UL_STYLES) do
      spec[s] = nil
    end
    spec[style] = true
    spec.sp = line.fg or line.sp or spec.fg
    spec.cterm = vim.tbl_extend('force', spec.cterm or {}, { underline = true })
  end
  api.nvim_set_hl(0, name, spec)
end

---Group to actually use: the twin when underline is on or for treesitter groups.
local function hlname(group)
  if not ul_style() and group:byte(1) ~= 64 then -- '@'
    return group
  end
  local name = derived[group]
  if not name then
    name = 'WinbarHl' .. group:gsub('[^%w]', '_')
    derived[group] = name
    define_twin(group, name)
  end
  return name
end

local function hl(group, text)
  return '%#' .. hlname(group) .. '#' .. text
end

local function esc(s) -- '%' is special in statusline
  return (s:gsub('%%', '%%%%'))
end

local function clean(s) -- some servers' symbol names contain newlines / control chars
  return (s:gsub('[%z\1-\31\127]+', ' '))
end

---Truncate by display width, ending with an ellipsis. Only cuts at codepoint
---boundaries; width is always computed via nvim_strwidth (so CJK / emoji /
---combining chars match what Neovim actually renders). ASCII fast path skips
---the codepoint scan + binary search entirely; otherwise binary search finds
---the longest prefix that fits.
---@return string text, integer width
local function truncate(s, max)
  local w = strwidth(s)
  if w <= max then
    return s, w
  end
  local limit = max - ell_w
  if limit <= 0 then
    return config.ellipsis, ell_w
  end
  if #s == w then -- ASCII fast path: 1 byte = 1 column
    return s:sub(1, limit) .. config.ellipsis, limit + ell_w
  end
  if #s > 4096 then
    s = s:sub(1, 4096)
  end
  local ends, n = {}, 0 -- ends[k] = byte offset of the end of the k-th codepoint
  for i = 1, #s do
    local nb = s:byte(i + 1)
    if not nb or nb < 0x80 or nb >= 0xC0 then
      n = n + 1
      ends[n] = i
    end
  end
  local lo, hi, cut, cw = 1, n, 0, 0
  while lo <= hi do
    local mid = floor((lo + hi) / 2)
    local pw = strwidth(s:sub(1, ends[mid]))
    if pw <= limit then
      cut, cw, lo = ends[mid], pw, mid + 1
    else
      hi = mid - 1
    end
  end
  return s:sub(1, cut) .. config.ellipsis, cw + ell_w
end

-- ── symbol tree ──────────────────────────────────────────────────────────

local function before(a, b) -- ascending by start; equal start -> larger range (outer) first; then by server order
  if a.sr ~= b.sr then
    return a.sr < b.sr
  end
  if a.sc ~= b.sc then
    return a.sc < b.sc
  end
  if a.er ~= b.er then
    return a.er > b.er
  end
  if a.ec ~= b.ec then
    return a.ec > b.ec
  end
  return a.i < b.i
end

---Extract line, character from an LSP Position; returns nil on malformed input.
---(Since Nvim 0.12, JSON null is vim.NIL rather than nil, so always check via type()).
local function position(p)
  if type(p) == 'table' and type(p.line) == 'number' and type(p.character) == 'number' then
    return p.line, p.character
  end
end

---Flatten DocumentSymbol[] (hierarchical) and SymbolInformation[] (flat) into
---a single pre-order node list. When include_kinds is set, nodes of other
---kinds are dropped here; their children are still walked, so surviving
---descendants are reparented by range containment in build().
local function flatten(symbols, out)
  for _, s in ipairs(symbols) do
    if type(s) == 'table' then
      local r = type(s.range) == 'table' and s.range
        or (type(s.location) == 'table' and s.location.range)
      local sel = type(s.selectionRange) == 'table' and s.selectionRange or r
      if type(r) == 'table' and (not include_kinds or include_kinds[s.kind]) then
        local sr, sc = position(r.start)
        local er, ec = position(r['end'])
        local jr, jc = position(sel.start) -- click target / signature start: where the name is
        if sr and er then
          local i = #out + 1
          out[i] = {
            name = type(s.name) == 'string' and s.name or '',
            kind = s.kind,
            sr = sr,
            sc = sc,
            er = er,
            ec = ec,
            jr = jr or sr,
            jc = jc or sc,
            i = i,
          }
        end
      end
      if type(s.children) == 'table' then
        flatten(s.children, out)
      end
    end
  end
  return out
end

---Build a tree from range containment. Guarantees that each level is ordered
---by start position and mutually non-overlapping, so each level can be binary
---searched; also tolerates flat SymbolInformation[] and the occasional
---misordered hierarchy from some servers.
local function build(result)
  local list = flatten(result, {})
  local n = #list
  for i = 2, n do
    if before(list[i], list[i - 1]) then -- most servers already return document order; skip sort when possible
      table.sort(list, before)
      break
    end
  end
  local roots, stack, top = {}, {}, 0
  for i = 1, n do
    local node = list[i]
    while top > 0 do -- pop ancestors that don't contain the current node
      local p = stack[top]
      if p.er > node.er or (p.er == node.er and p.ec >= node.ec) then
        break
      end
      top = top - 1
    end
    local siblings = roots
    if top > 0 then
      local p = stack[top]
      siblings = p.children
      if not siblings then
        siblings = {}
        p.children = siblings
      end
    end
    siblings[#siblings + 1] = node
    top = top + 1
    stack[top] = node
  end
  return roots
end

-- ── cursor location ────────────────────────────────────────────────────

local function utfindex(line, enc, col) -- byte col -> utf-16 / utf-32 col
  if NVIM_011 then
    return vim.str_utfindex(line, enc, col, false)
  end
  local ok, u32, u16 = pcall(vim.str_utfindex, line, col)
  if not ok then
    return col
  end
  return enc == 'utf-32' and u32 or u16
end

local function byteindex(line, enc, col) -- utf-16 / utf-32 col -> byte col
  if enc == 'utf-8' then
    return math.min(col, #line)
  end
  if NVIM_011 then
    return vim.str_byteindex(line, enc, col, false)
  end
  local ok, byte = pcall(vim.str_byteindex, line, col, enc == 'utf-16')
  return ok and byte or math.min(col, #line)
end

local q_buf, q_row, q_bcol, q_enc, q_col -- cursor for the current query

---Convert the cursor column to the server's position encoding (LSP defaults
---to utf-16; the cursor col is a byte col; these differ when the line
---contains multibyte chars). Only needed when comparisons land on the same
---line, so compute lazily, at most once per query.
local function qcol()
  if q_col then
    return q_col
  end
  q_col = q_bcol
  if q_bcol > 0 and q_enc ~= 'utf-8' then
    local line = api.nvim_buf_get_lines(q_buf, q_row, q_row + 1, false)[1]
    if line and line:find('[\128-\255]') then
      q_col = utfindex(line, q_enc, q_bcol)
    end
  end
  return q_col
end

---Binary search a single level (ordered, non-overlapping) for the node containing the cursor.
local function find(list, row)
  local lo, hi, hit = 1, #list, nil
  while lo <= hi do
    local mid = floor((lo + hi) / 2)
    local n = list[mid]
    if n.sr < row or (n.sr == row and n.sc <= qcol()) then
      hit, lo = n, mid + 1
    else
      hi = mid - 1
    end
  end
  if hit and (hit.er > row or (hit.er == row and hit.ec > qcol())) then
    return hit
  end
end

-- ── fragments ────────────────────────────────────────────────────────────

local function file_icon(name)
  if _G.MiniIcons then
    local ok, icon, group = pcall(_G.MiniIcons.get, 'file', name)
    if ok and icon then
      return icon, group
    end
  end
  local ok, devicons = pcall(require, 'nvim-web-devicons')
  if ok then
    local icon, group = devicons.get_icon(name, name:match('%.([^.]+)$'), { default = true })
    if icon then
      return icon, group
    end
  end
  return ''
end

---Path fragments only depend on the buffer name / cwd, so cache one per buffer.
local function build_path(buf)
  local dirs, file = {}, nil
  if config.path ~= 'none' then
    local name =
      fn.fnamemodify(api.nvim_buf_get_name(buf), config.path == 'name' and ':t' or ':~:.')
    local parts = vim.split(name, PATH_SEP, { trimempty = true })
    local tail = clean(table.remove(parts) or '')
    for _, dir in ipairs(parts) do
      if dir ~= '' then
        local text, w = truncate(clean(dir), config.max_name_width)
        dirs[#dirs + 1] = { hl('WinbarDir', esc(text)), w }
      end
    end
    local text, w = hl('WinbarFile', esc(tail)), strwidth(tail) -- file name is never truncated
    local icon, group = '', nil
    if config.icons then
      icon, group = file_icon(tail)
    end
    if icon ~= '' then
      text, w = hl(group or 'WinbarFile', esc(icon) .. ' ') .. text, w + strwidth(icon) + 1
    end
    file = { text, w }
  end
  return { dirs = dirs, file = file }
end

-- Treesitter capture -> highlight group, resolved the way Neovim's highlighter
-- does: try @capture.lang, then drop trailing segments until a defined group.
local ts_cache = {}
local TS_SKIP = { spell = true, nospell = true, conceal = true, none = true }

local function ts_group(capture, lang)
  local key = capture .. '.' .. lang
  local g = ts_cache[key]
  if g == nil then
    g = false
    local name = '@' .. key
    while name do
      if next(api.nvim_get_hl(0, { name = name })) then
        g = name
        break
      end
      name = name:match('^(@.+)%.[^.]+$')
    end
    ts_cache[key] = g
  end
  return g or nil
end

---Treesitter highlight of rows row0 .. row0 + #lines - 1.
---@return table? map map[i][col] = group for byte col of lines[i]
local function ts_highlights(buf, row0, lines)
  local ok, parser = pcall(vim.treesitter.get_parser, buf)
  if not ok or not parser then
    return
  end
  local r1 = row0 + #lines - 1
  local range = { row0, 0, r1, #lines[#lines] }
  pcall(parser.parse, parser, { row0, r1 + 1 }) -- usually a no-op: the highlighter keeps it parsed
  local ok2, lt = pcall(parser.language_for_range, parser, range)
  if not ok2 or not lt then
    return
  end
  local tree = lt.tree_for_range and lt:tree_for_range(range) or lt:trees()[1]
  local lang = lt:lang()
  local ok3, query = pcall(vim.treesitter.query.get, lang, 'highlights')
  if not tree or not ok3 or not query then
    return
  end
  local map, prio = {}, {}
  for id, node, md in query:iter_captures(tree:root(), buf, row0, r1 + 1) do
    local name = query.captures[id]
    local group = not TS_SKIP[name] and name:byte(1) ~= 95 and ts_group(name, lang) -- '_'
    if group then
      local p = tonumber(md and (md.priority or (md[id] and md[id].priority))) or 100
      local sr, sc, er, ec = node:range()
      for r = math.max(sr, row0), math.min(er, r1) do
        local i = r - row0 + 1
        local m, pr = map[i], prio[i]
        if not m then
          m, pr = {}, {}
          map[i], prio[i] = m, pr
        end
        local c2 = r == er and ec or #lines[i]
        for c = (r == sr and sc or 0) + 1, c2 do
          if not pr[c] or p >= pr[c] then -- later capture wins at equal priority, like the highlighter
            m[c], pr[c] = group, p
          end
        end
      end
    end
  end
  return map
end

---Read `name(params) -> ret` from the source, starting at the symbol name
---(selectionRange start) and stopping at the first '{' / ';' outside the
---parameter parentheses, or at the end of the line where they close. This
---drops prefixes like `pub fn` / `def` / `function` and the body. Multi-line
---signatures are joined into one line. With config.signature_hl, every byte
---keeps its treesitter highlight group.
---Returns a list of runs { text, group|nil }, or nil when no parameter list is
---found (the caller then falls back to the plain name).
---Known limits: parentheses inside strings / comments in the parameter list
---are counted too; a return type on a line after the closing ')' is lost.
local function signature(n, buf, enc)
  local lines = api.nvim_buf_get_lines(buf, n.jr, n.jr + SIG_MAX_LINES, false)
  if not lines[1] then
    return
  end
  local slices, depth, seen = {}, 0, false -- slices[i] = { from, to } byte range of lines[i]
  for i, line in ipairs(lines) do
    local from = i == 1 and byteindex(line, enc, n.jc) + 1 or 1
    local to = #line
    for j = from, #line do -- only ASCII delimiters matter, so scanning bytes is fine
      local c = line:byte(j)
      if c == 40 then -- (
        depth, seen = depth + 1, true
      elseif c == 41 then -- )
        depth = depth - 1
      elseif depth <= 0 and (c == 123 or c == 59) then -- { ;
        to = j - 1
        slices[i] = { from, to }
        break
      end
    end
    if slices[i] then
      break
    end
    slices[i] = { from, to }
    if seen and depth <= 0 then
      break
    end
  end
  if not seen then
    return
  end
  local used = {}
  for i = 1, #slices do
    used[i] = lines[i]
  end
  local map = config.signature_hl and ts_highlights(buf, n.jr, used) or {}

  -- Normalize byte by byte while keeping each byte's group: collapse
  -- whitespace (line breaks included), drop spaces after '(' and before ')',
  -- and a trailing comma before ')'.
  local ch, gr, k = {}, {}, 0
  local function push(c, g)
    k = k + 1
    ch[k], gr[k] = c, g
  end
  local function pop_spaces()
    while k > 0 and ch[k] == ' ' do
      ch[k], gr[k], k = nil, nil, k - 1
    end
  end
  for i, sl in ipairs(slices) do
    local line, m = used[i], map[i] or {}
    if i > 1 and k > 0 and ch[k] ~= ' ' and ch[k] ~= '(' then
      push(' ')
    end
    for c = sl[1], sl[2] do
      local b = line:byte(c)
      if b <= 32 or b == 127 then
        if k > 0 and ch[k] ~= ' ' and ch[k] ~= '(' then
          push(' ', m[c]) -- keeps e.g. the string color for spaces inside literals
        end
      elseif b == 41 then -- )
        pop_spaces()
        if k > 0 and ch[k] == ',' then
          ch[k], gr[k], k = nil, nil, k - 1
          pop_spaces()
        end
        push(')', m[c])
      else
        push(line:sub(c, c), m[c])
      end
    end
  end
  local where = table.concat(ch, '', 1, k):find('%swhere%f[^%w_]') -- rust `where` clause
  if where then
    k = where - 1
  end
  while k > 0 and (ch[k] == ' ' or ch[k] == ':') do -- trailing whitespace / python ':'
    k = k - 1
  end
  if k == 0 then
    return
  end

  local runs, cur, buf_s = {}, nil, {}
  for i = 1, k + 1 do
    local g = gr[i]
    if i > k or (g ~= cur and #buf_s > 0) then
      if #buf_s > 0 then
        runs[#runs + 1] = { table.concat(buf_s), cur }
      end
      buf_s = {}
    end
    if i <= k then
      cur = g
      buf_s[#buf_s + 1] = ch[i]
    end
  end
  return runs
end

---Emit runs { text, group|nil } (nil = default group) within max display
---columns, ending with an ellipsis when cut.
---@return string text, integer width
local function emit(runs, max, default)
  local plain = {}
  for i, r in ipairs(runs) do
    plain[i] = r[1]
  end
  plain = table.concat(plain)
  local t, w = truncate(plain, max)
  local keep = t == plain and #plain or #t - #config.ellipsis -- bytes of plain to keep
  local out, pos = {}, 0
  for _, r in ipairs(runs) do
    if pos >= keep then
      break
    end
    local s = r[1]
    if pos + #s > keep then
      s = s:sub(1, keep - pos)
    end
    out[#out + 1] = hl(r[2] or default, esc(s))
    pos = pos + #r[1]
  end
  if keep < #plain then
    out[#out + 1] = hl('WinbarEllipsis', esc(config.ellipsis))
  end
  return table.concat(out), w
end

---Symbol fragment: optional icon + label (+ clickable region).
---The label is the name, or `name(params) -> ret` when config.signature = true
---(colored by treesitter when config.signature_hl = true). Uncolored parts use
---the kind's highlight group (WinbarKind<Name>); the icon is only prepended
---when config.icons = true, and shares the same highlight group.
---Where WinbarKind<Name> ultimately links to is controlled by config.semantic,
---see set_hl(). The node's depth in the tree is fixed, so it's reused directly
---as the click callback argument.
---@return string text, integer width
local function symbol_text(n, depth, max, buf, enc)
  local kind = kinds[n.kind] or NO_KIND
  local runs = config.signature and signature(n, buf, enc) or { { clean(n.name) } }
  local label, w = emit(runs, max, kind[3])
  local text = kind[1] .. label
  if config.clickable then
    text = '%' .. depth .. CLICK .. text .. '%T'
  end
  return text, kind[2] + w
end

---Compose the final winbar string. When it doesn't fit, in order:
---① collapse directories from the left ② collapse symbols from the outside in
---③ truncate the innermost symbol label; if still not enough, let Neovim clip from the left.
local function compose(buf, b, path, depth, width, modified)
  local p = b.path
  if not p then
    p = build_path(buf)
    b.path = p
  end
  local dirs, file = p.dirs, p.file
  local nd = #dirs
  local d1, s1 = 1, 1 -- first visible dir / symbol
  if config.max_depth > 0 and depth > config.max_depth then
    s1 = depth - config.max_depth + 1
  end
  local d_ell, s_ell = false, s1 > 1 -- whether an ellipsis precedes dirs / symbols due to collapsing

  local limit = config.max_width > 0 and math.min(config.max_width, width) or width
  local avail = limit - 2 * config.padding
  local total = -sep_w -- N fragments only need N-1 separators
  for i = 1, nd do
    total = total + dirs[i][2] + sep_w
  end
  if file then
    total = total + file[2] + sep_w + (modified and mod_w or 0)
  end
  if s_ell then
    total = total + ell_w + sep_w
  end
  local sym_max = config.signature and config.max_signature_width or config.max_name_width
  for i = s1, depth do
    local n = path[i]
    if not n.text then
      n.text, n.w = symbol_text(n, i, sym_max, buf, b.enc)
    end
    total = total + n.w + sep_w
  end

  while total > avail and d1 <= nd do -- ①
    total = total - dirs[d1][2] - sep_w
    if not d_ell then
      d_ell, total = true, total + ell_w + sep_w
    end
    d1 = d1 + 1
  end
  if total > avail and d_ell then -- dirs fully collapsed and still too wide: drop its ellipsis too
    d_ell, total = false, total - ell_w - sep_w
  end
  while total > avail and s1 < depth do -- ②
    total = total - path[s1].w - sep_w
    if not s_ell then
      s_ell, total = true, total + ell_w + sep_w
    end
    s1 = s1 + 1
  end
  local leaf_text
  if total > avail and depth > 0 then -- ③
    local n = path[depth]
    local room = n.w - (kinds[n.kind] or NO_KIND)[2] - (total - avail)
    if room > ell_w then
      leaf_text = symbol_text(n, depth, room, buf, b.enc)
    end
  end

  local out, k = { pad }, 1
  local function add(text)
    if k > 1 then
      k = k + 1
      out[k] = sep
    end
    k = k + 1
    out[k] = text
  end
  if d_ell then
    add(ell)
  end
  for i = d1, nd do
    add(dirs[i][1])
  end
  if file then
    add(modified and file[1] .. mod or file[1])
  end
  if s_ell then
    add(ell)
  end
  for i = s1, depth do
    add(i == depth and leaf_text or path[i].text)
  end
  out[k + 1] = fill_hl
  return table.concat(out)
end

-- ── window attachment ─────────────────────────────────────────────────────

local function eligible(win, buf)
  return fn.win_gettype(win) == '' -- exclude floats / preview / quickfix / cmdwin
    and vim.bo[buf].buftype == ''
    and not vim.wo[win].diff -- diff sides must stay line-aligned, can't add a line to only one side
    and api.nvim_buf_get_name(buf) ~= ''
    and not excluded[vim.bo[buf].filetype]
    and (not config.enabled or config.enabled(buf, win))
end

---Only touch the window-local 'winbar': set the expression if eligible,
---remove it if not eligible and it was set by us.
local function refresh_win(win)
  if not api.nvim_win_is_valid(win) then
    wins[win] = nil
    return
  end
  local opt = { scope = 'local', win = win }
  local cur = api.nvim_get_option_value('winbar', opt)
  if eligible(win, api.nvim_win_get_buf(win)) then
    if cur == '' then
      pcall(api.nvim_set_option_value, 'winbar', EXPR, opt)
    end -- don't override a winbar set by another plugin
  elseif cur == EXPR then
    wins[win] = nil
    pcall(api.nvim_set_option_value, 'winbar', '', opt)
  end
end

-- ── LSP documentSymbol ─────────────────────────────────────────────────────

---Buffer data changed: bump its version to invalidate caches, and redraw the
---winbar of every window showing it.
local function invalidate(buf, b)
  b.ver = next_ver()
  for _, win in ipairs(fn.win_findbuf(buf)) do
    local w = wins[win]
    if w then
      w.leaf, w.path = nil, nil -- drop references to the old tree
    end
    if not pcall(api.nvim__redraw, { win = win, winbar = true }) then
      vim.cmd('redrawstatus!')
    end
  end
end

local function client_request(client, ...)
  if NVIM_011 then
    return client:request(...)
  end
  return client.request(...)
end

local function client_cancel(client, id)
  if NVIM_011 then
    return client:cancel_request(id)
  end
  return client.cancel_request(id)
end

local request -- forward declaration: used by the timer callback and retry()

---(Re)start the buffer's debounce timer; restarting resets it.
local function schedule(buf, b, delay)
  if not b.timer then
    b.timer = uv.new_timer()
    b.fire = vim.schedule_wrap(function()
      request(buf, b)
    end)
  end
  b.timer:start(delay, 0, b.fire)
end

local function schedule_update(buf, b, delay)
  if b.tick == api.nvim_buf_get_changedtick(buf) then
    return
  end
  schedule(buf, b, delay or b.delay or config.debounce)
end

---Empty result or error: the server may still be starting / indexing. Retry
---with exponential backoff, a bounded number of times. Once exhausted, b.tick
---stays at the requested changedtick, so CursorHold & co. no longer resend for
---unchanged text; the next edit, LspAttach or LspProgress(end) tries again.
local function retry(buf, b)
  if b.retries >= MAX_RETRIES then
    return
  end
  b.retries = b.retries + 1
  b.tick = -1
  schedule(buf, b, floor(math.max(config.debounce, 100) * 2 ^ b.retries))
end

function request(buf, b)
  if bufs[buf] ~= b or not api.nvim_buf_is_loaded(buf) then
    return
  end
  local tick = api.nvim_buf_get_changedtick(buf)
  if b.tick == tick then
    return
  end -- this version of the text was already requested
  if not fn.win_findbuf(buf)[1] then
    return
  end -- not displayed anywhere: BufWinEnter requests later (no bursts on :checktime / :LspRestart)
  if b.cancel then
    b.cancel()
    b.cancel = nil
  end -- previous request hasn't returned yet: cancel it
  local gen = b.gen + 1
  b.gen = gen -- even if cancel doesn't take effect, any prior response is void
  b.tick = tick -- recorded even without a client: wait for LspAttach instead of polling
  local client = lsp.get_clients({ bufnr = buf, method = METHOD })[1]
  if not client then
    if b.symbols then
      b.symbols = nil
      invalidate(buf, b)
    end
    return
  end
  local params = { textDocument = lsp.util.make_text_document_params(buf) }
  local t0 = uv.hrtime()
  local ok, sent, id = pcall(client_request, client, METHOD, params, function(err, result)
    if bufs[buf] ~= b or b.gen ~= gen then
      return
    end -- stale response
    b.cancel = nil
    -- adaptive debounce: don't ask a slow server (or for a huge file) more often than it can answer
    local rtt = (uv.hrtime() - t0) / 1e6
    b.delay = math.min(MAX_DELAY, math.max(config.debounce, floor(rtt)))
    if err ~= nil and err ~= vim.NIL then
      return retry(buf, b)
    end
    local symbols = build(type(result) == 'table' and result or {})
    local had = b.symbols ~= nil and #b.symbols > 0
    b.symbols, b.enc = symbols, client.offset_encoding or 'utf-16'
    b.empty = #symbols == 0
    if b.empty then
      retry(buf, b) -- server may not be ready yet
    else
      b.retries = 0
    end
    if had or not b.empty then
      invalidate(buf, b)
    end
  end, buf)
  if ok and sent and id then
    b.cancel = function()
      pcall(client_cancel, client, id)
    end
  else
    retry(buf, b)
  end
end

local function track(buf)
  local b = { ver = next_ver(), tick = -1, enc = 'utf-16', gen = 0, retries = 0 }
  bufs[buf] = b
  schedule(buf, b, 0)
  return b
end

local function drop(buf)
  local b = bufs[buf]
  if not b then
    return
  end
  bufs[buf] = nil
  if b.cancel then
    b.cancel()
  end
  if b.timer then
    b.timer:stop()
    if not b.timer:is_closing() then
      b.timer:close()
    end
  end
end

-- ── render (hot path) ──────────────────────────────────────────────────────

local scratch = {} -- reused path buffer
local bopt = { buf = 0 }

local function render()
  local win = api.nvim_get_current_win() -- curwin is the window being drawn during %{%..%} evaluation
  local buf = api.nvim_win_get_buf(win)
  local w = wins[win]
  if not w or w.buf ~= buf then
    if not eligible(win, buf) then -- floats / new splits inherit window options: clear it later
      vim.schedule(function()
        refresh_win(win)
      end)
      return ''
    end
    w = { buf = buf }
    wins[win] = w
  end
  local b = bufs[buf] or track(buf)
  local width = api.nvim_win_get_width(win)
  local cur = api.nvim_win_get_cursor(win)
  local row, col = cur[1] - 1, cur[2]
  local modified = false
  if mod then
    bopt.buf = buf
    modified = api.nvim_get_option_value('modified', bopt)
  end
  local fresh = w.ver == b.ver and w.width == width and w.mod == modified
  if fresh and w.row == row and w.col == col then
    return w.str
  end -- nothing changed

  -- Walk the symbol tree level by level via binary search to get the root -> cursor path
  local depth, list = 0, b.symbols
  if list then
    q_buf, q_row, q_bcol, q_enc, q_col = buf, row, col, b.enc, nil
    while list do
      local n = find(list, row)
      if not n then
        break
      end
      depth = depth + 1
      scratch[depth] = n
      list = n.children
    end
  end
  local leaf = scratch[depth]
  w.row, w.col = row, col
  if fresh and w.leaf == leaf then
    return w.str
  end -- cursor moved but still inside the same symbol

  local path = w.path
  if not path then
    path = {}
    w.path = path
  end
  for i = 1, depth do
    path[i] = scratch[i]
  end
  for i = #path, depth + 1, -1 do
    path[i] = nil
  end
  w.ver, w.width, w.mod, w.leaf = b.ver, width, modified, leaf
  w.str = compose(buf, b, path, depth, width, modified)
  return w.str
end

local reported = false

---Entry point for the 'winbar' expression.
function M.render()
  local ok, res = pcall(render)
  if ok then
    return res
  end
  if not reported then -- report errors only once, don't spam on every redraw
    reported = true
    vim.schedule(function()
      vim.notify('[winbar] ' .. tostring(res), vim.log.levels.ERROR)
    end)
  end
  return ''
end

---Click callback: depth is the clicked symbol's level in the path.
function M.click(depth, _, button)
  if button ~= 'l' then
    return
  end
  local win = fn.getmousepos().winid
  local w = wins[win]
  local n = w and w.path and w.path[depth]
  if not n or not api.nvim_win_is_valid(win) then
    return
  end
  local buf = api.nvim_win_get_buf(win)
  local b = bufs[buf]
  local line = api.nvim_buf_get_lines(buf, n.jr, n.jr + 1, false)[1]
  if w.buf ~= buf or not b or not line then
    return
  end
  api.nvim_set_current_win(win)
  vim.cmd("normal! m'") -- record in jumplist, <C-o> to jump back
  api.nvim_win_set_cursor(win, { n.jr + 1, byteindex(line, b.enc, n.jc) })
  vim.cmd('normal! zv')
end

-- ── setup ──────────────────────────────────────────────────────────────────

local function set_hl()
  local function link(name, target, soft)
    api.nvim_set_hl(0, name, { link = target, default = soft ~= false })
  end
  link('WinbarDir', 'Comment')
  link('WinbarSep', 'Comment')
  link('WinbarEllipsis', 'Comment')
  link('WinbarFile', 'WinBar')
  link('WinbarSymbol', 'WinBar')
  link('WinbarModified', 'DiagnosticWarn')
  link('WinbarUnderline', 'WinSeparator')
  for _, k in ipairs(KINDS) do
    -- false (default): same as WinbarSymbol, no per-kind color (vscode-like).
    -- true: prefer @lsp.type.<type> semantic highlight; kinds without a mapped
    --       type fall back to WinbarSymbol.
    local target = 'WinbarSymbol'
    if config.semantic then
      local lsp_type = LSP_TYPE[k[1]]
      target = lsp_type and ('@lsp.type.' .. lsp_type) or 'WinbarSymbol'
    end
    -- These groups are derived from config.semantic and must be refreshed on
    -- every setup()/ColorScheme, so don't use default=true (it would stick to
    -- whatever was set the first time).
    link('WinbarKind' .. k[1], target, false)
  end
  -- twins copy their source's colors: recompute after every change
  for src, name in pairs(derived) do
    define_twin(src, name)
  end
end

local function prepare()
  sep, sep_w = hl('WinbarSep', esc(config.separator)), strwidth(config.separator)
  ell, ell_w = hl('WinbarEllipsis', esc(config.ellipsis)), strwidth(config.ellipsis)
  pad = (' '):rep(config.padding)
  fill_hl = '%*'
  if ul_style() then -- padding and the empty rest of the line need the underline too
    pad = hl('WinBar', pad)
    fill_hl = '%#' .. hlname('WinBar') .. '#'
  end
  NO_KIND = { '%#' .. hlname('WinbarSymbol') .. '#', 0, 'WinbarSymbol' }
  mod, mod_w = nil, 0
  if config.modified then
    mod, mod_w = ' ' .. hl('WinbarModified', esc(config.modified)), 1 + strwidth(config.modified)
  end
  excluded = {}
  for _, ft in ipairs(config.exclude_filetypes) do
    excluded[ft] = true
  end
  -- The label always uses the WinbarKind<Name> highlight group. The icon is
  -- only prepended when config.icons = true, sharing the same highlight group.
  -- What WinbarKind<Name> ultimately links to is controlled by config.semantic,
  -- see set_hl().
  kinds = {}
  for id, k in ipairs(KINDS) do
    local group = 'WinbarKind' .. k[1]
    local prefix, prefix_w = '', 0
    if config.icons then
      local icon = config.kinds[k[1]] or fn.nr2char(k[2])
      if icon ~= '' then
        prefix, prefix_w = hl(group, esc(icon) .. ' '), strwidth(icon) + 1
      end
    end
    kinds[id] = { prefix .. '%#' .. hlname(group) .. '#', prefix_w, group }
  end
  -- include_kinds: set of LSP symbol-kind ids to keep; nil = keep everything.
  -- Filtered-out nodes are dropped in flatten(); surviving descendants are
  -- reparented to the nearest surviving ancestor by range containment.
  include_kinds = nil
  if config.include_kinds and #config.include_kinds > 0 then
    local name_to_id = {}
    for id, k in ipairs(KINDS) do
      name_to_id[k[1]] = id
    end
    include_kinds = {}
    for _, name in ipairs(config.include_kinds) do
      local id = name_to_id[name]
      if id then
        include_kinds[id] = true
      end
    end
  end
end

function M.setup(opts)
  config = vim.tbl_extend('force', config, opts or {})
  derived, ts_cache = {}, {}
  set_hl() -- before prepare(): underlined twins are derived from these groups
  prepare()
  wins = {}
  for buf, b in pairs(bufs) do -- re-setup: drop caches built under the old config, re-request
    b.path, b.symbols, b.tick, b.ver = nil, nil, -1, next_ver()
    b.retries, b.delay, b.empty = 0, nil, nil
    if api.nvim_buf_is_valid(buf) then
      schedule_update(buf, b, 0)
    end
  end

  local group = api.nvim_create_augroup('winbar.breadcrumbs', { clear = true })
  local function au(events, callback, pattern)
    api.nvim_create_autocmd(events, { group = group, pattern = pattern, callback = callback })
  end

  -- attach / detach: buffer enters a window, or its type / name changes
  local function refresh_buf(a)
    local b = bufs[a.buf]
    if b and a.event == 'BufFilePost' then
      b.path, b.ver = nil, next_ver()
    end
    for _, win in ipairs(fn.win_findbuf(a.buf)) do
      refresh_win(win)
    end
    if b and a.event == 'BufWinEnter' then
      schedule_update(a.buf, b, 0) -- text may have changed (or never been requested) while hidden
    end
  end
  au({ 'BufWinEnter', 'BufWritePost', 'BufFilePost', 'FileType', 'TermOpen' }, refresh_buf)
  au('OptionSet', refresh_buf, { 'buftype', 'diff' })
  au('WinNew', function()
    refresh_win(api.nvim_get_current_win())
  end)

  -- text may have changed -> debounce, then re-request symbols (no-op if changedtick is unchanged).
  -- TextChanged also fires after leaving Insert mode and when entering a buffer modified while
  -- not current; BufWinEnter (refresh_buf) covers hidden buffers; retries are timer-driven.
  -- So BufEnter / CursorHold / InsertLeave are not needed.
  au({ 'BufReadPost', 'FileChangedShellPost', 'TextChanged' }, function(a)
    local b = bufs[a.buf]
    if b then
      schedule_update(a.buf, b)
    end
  end)
  au('LspAttach', function(a)
    local b = bufs[a.buf]
    if b then
      b.tick, b.retries = -1, 0
      schedule_update(a.buf, b)
    end
  end)
  au('LspDetach', function(a)
    local buf, b = a.buf, bufs[a.buf]
    if not b then
      return
    end
    vim.schedule(
      function() -- wait until the client is actually detached: try another client, or clear
        if bufs[buf] == b and api.nvim_buf_is_valid(buf) then
          b.tick = -1
          request(buf, b)
        end
      end
    )
  end)
  if fn.exists('##LspProgress') == 1 then
    -- A server finished some work (e.g. workspace indexing): buffers that got an
    -- empty result from it get exactly one more request (retries stay exhausted).
    au('LspProgress', function(a)
      local id = type(a.data) == 'table' and a.data.client_id
      if not id then
        return
      end
      for buf, b in pairs(bufs) do
        if b.empty and lsp.get_clients({ id = id, bufnr = buf })[1] then
          b.tick = -1
          schedule_update(buf, b)
        end
      end
    end, 'end')
  end

  au('DirChanged', function() -- relative paths changed
    for buf, b in pairs(bufs) do
      b.path = nil
      invalidate(buf, b)
    end
  end)
  au('WinClosed', function(a)
    wins[tonumber(a.match)] = nil
  end)
  au({ 'BufDelete', 'BufWipeout' }, function(a)
    drop(a.buf)
  end)
  au('ColorScheme', function()
    set_hl()
    if config.signature and config.signature_hl then
      -- the new scheme may define other @capture.lang groups: rebuild cached labels
      ts_cache = {}
      for buf, b in pairs(bufs) do
        b.tick = -1
        schedule_update(buf, b, 0)
      end
    end
  end)

  for _, win in ipairs(api.nvim_list_wins()) do
    refresh_win(win)
  end
end

return M
