local group = vim.api.nvim_create_augroup('Dashboard', { clear = true })

local M = {}

local config = {
  shortcuts = {
    { key = 'f', desc = 'Open File', action = '<cmd>FzfLua files<CR>' },
    { key = 'o', desc = 'Recent Files', action = '<cmd>FzfLua oldfiles<CR>' },
    {
      key = 'd',
      desc = 'Dotfiles',
      action = '<cmd>:FzfLua files cwd=~/.config fd_opts=--type\\ f<CR>',
    },
    { key = 'e', desc = 'New File', action = '<cmd>enew<CR>' },
    {
      key = 'u',
      desc = 'Update Plugins',
      action = '<cmd>lua vim.pack.update(nil, { force = true})<CR>',
    },
    { key = 'q', desc = 'Quit', action = '<cmd>qa<CR>' },
  },

  border = false, -- show the rounded border with the running light
  menu_columns = 3, -- shortcuts per row
  inner_width = 54, -- display columns between the two vertical borders
  frame_min_columns = 60, -- below this the frame (and its animation) is dropped
  tick_ms = 50,
  ring_tail = 4,
  clock_min_height = 44, -- hide the clock below this window height
  logo_step = 3, -- logo cells the dot travels per tick
  logo_hold_ticks = 120, -- how long the finished rainbow keeps flowing
  rainbow_steps = 24, -- number of gradient highlight groups
  -- logo colours (top -> bottom shades): b = left leg, c = diagonal, r = right leg
  logo_palette = {
    b = { '#4aa6ea', '#3c92d2', '#307fbb', '#256ca5' },
    c = { '#8bd46a', '#74c05a', '#62ad4c', '#559b42' },
    r = { '#6cb856', '#5fab4b', '#529a41', '#468a38' },
  },

  highlights = {
    border = 'DashboardBorder',
    ring = { 'DashboardRing1', 'DashboardRing2', 'DashboardRing3', 'DashboardRing3' },
    logo_color = 'DashboardLogo', -- suffixed with kind (B/C/R) and shade 1..4
    logo_head = 'DashboardLogoHead',
    rainbow = 'DashboardRainbow', -- suffixed with 1..rainbow_steps
    clock = 'DashboardClock',
    date = 'DashboardDate',
    key = 'DashboardKey',
    desc = 'DashboardDesc',
    footer = 'DashboardFooter',
  },
}

local glyphs = {
  ['0'] = { '┏━┓', '┃ ┃', '┗━┛' },
  ['1'] = { '╺┓ ', ' ┃ ', '╺┻╸' },
  ['2'] = { '┏━┓', '┏━┛', '┗━━' },
  ['3'] = { '┏━┓', '╺━┫', '┗━┛' },
  ['4'] = { '╻ ╻', '┗━┫', '  ╹' },
  ['5'] = { '┏━━', '┗━┓', '┗━┛' },
  ['6'] = { '┏━┓', '┣━┓', '┗━┛' },
  ['7'] = { '┏━┓', '  ┃', '  ╹' },
  ['8'] = { '┏━┓', '┣━┫', '┗━┛' },
  ['9'] = { '┏━┓', '┗━┫', '┗━┛' },
  -- braille dots sit near the lower/upper edge of their cell, which centres the colon
  [':'] = { '⢀', ' ', '⠈' },
}

-- braille rendering of the official Neovim mark; blank braille cells are skipped.
-- The art is rasterised at the real on-screen dot positions of a braille cell:
-- the 4 dot rows of a cell sit close together and the line spacing leaves a
-- much bigger gap to the next line, so the edges are drawn as straight lines in
-- screen space instead of on an evenly spaced dot grid. The diagonal moves
-- exactly 3 dots per text line (about the official 1.5 slope), so every line
-- repeats the same edge pattern. Gaps between the parts are wide enough that
-- each braille cell belongs to a single part and takes a single colour.
local logo = {
  '⠀⠀⠀⠀⠀⢀⣾⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣷⡀⠀⠀⠀⠀⠀',
  '⠀⠀⠀⢀⣾⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣷⡀⠀⠀⠀',
  '⠀⢀⣾⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣷⡀⠀',
  '⣦⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣷',
  '⣿⣿⡄⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿',
  '⣿⣿⣿⣧⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿',
  '⣿⣿⣿⣿⣿⡄⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⣿⣿⣿⣿⣿⣿⣿',
  '⣿⣿⣿⣿⣿⣿⣧⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠀⠀⣿⣿⣿⣿⣿⣿⣿',
  '⣿⣿⣿⣿⣿⣿⣿⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⢻⣿⣿⣿⣿⣿⣿',
  '⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠘⣿⣿⣿⣿⣿',
  '⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⢻⣿⣿⣿',
  '⣿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⣿⣿⡄⠘⣿⣿',
  '⢿⣿⣿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿⣿⣿⣧⠀⠻',
  '⠀⠈⢿⣿⣿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⣿⣿⣿⣿⣿⣿⣿⡿⠁⠀',
  '⠀⠀⠀⠈⢿⣿⣿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⡿⠁⠀⠀⠀',
  '⠀⠀⠀⠀⠀⠈⢿⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢻⡿⠁⠀⠀⠀⠀⠀',
}

-- colour kind of every logo cell (same shape as `logo`)
local logo_map = {
  '     ccc             rr     ',
  '   ccccccc           rrrr   ',
  ' cccccccccc          rrrrrr ',
  'b ccccccccccc        rrrrrrr',
  'bbbccccccccccc       rrrrrrr',
  'bbbb ccccccccccc     rrrrrrr',
  'bbbbbbccccccccccc    rrrrrrr',
  'bbbbbbb ccccccccccc  rrrrrrr',
  'bbbbbbb  ccccccccccc rrrrrrr',
  'bbbbbbb    cccccccccccrrrrrr',
  'bbbbbbb     ccccccccccc rrrr',
  'bbbbbbb       cccccccccccrrr',
  'bbbbbbb        ccccccccccc r',
  ' bbbbbb          cccccccccc ',
  '   bbbb           ccccccc   ',
  '     bb             ccc     ',
}

local ns = vim.api.nvim_create_namespace('dashboard')
local ns_anim = vim.api.nvim_create_namespace('dashboard_anim')

-- Runtime state of the (single) visible dashboard
local state = nil

local function hsv_to_hex(h, s, v)
  local function f(n)
    local k = (n + h / 60) % 6
    local c = v - v * s * math.max(0, math.min(k, 4 - k, 1))
    return math.floor(c * 255 + 0.5)
  end
  return string.format('#%02x%02x%02x', f(5), f(3), f(1))
end

local function setup_highlights()
  local hl = config.highlights
  local steps = config.rainbow_steps
  for i = 1, steps do
    local hue = (i - 1) / steps * 360
    vim.api.nvim_set_hl(0, hl.rainbow .. i, { fg = hsv_to_hex(hue, 0.55, 0.95), default = true })
  end
  vim.api.nvim_set_hl(0, hl.logo_head, { fg = '#ffffff', bold = true, default = true })
  for kind, shades in pairs(config.logo_palette) do
    for i, color in ipairs(shades) do
      vim.api.nvim_set_hl(0, hl.logo_color .. kind:upper() .. i, { fg = color, default = true })
    end
  end

  local links = {
    [hl.border] = 'Comment',
    [hl.ring[1]] = 'Special',
    [hl.ring[2]] = 'Function',
    [hl.ring[3]] = 'Type',
    [hl.clock] = 'PreProc',
    [hl.date] = 'Comment',
    [hl.key] = 'ErrorMsg',
    [hl.desc] = 'Function',
    [hl.footer] = 'Comment',
  }
  for name, link in pairs(links) do
    vim.api.nvim_set_hl(0, name, { link = link, default = true })
  end
end

local function center(text, width)
  local dw = vim.fn.strdisplaywidth(text)
  local left = math.max(0, math.floor((width - dw) / 2))
  return string.rep(' ', left) .. text, left
end

local function build_clock(time_str)
  local rows = { {}, {}, {} }
  local colon_offsets = {} -- { row, byte offset } inside the unpadded text
  for i = 1, #time_str do
    local ch = time_str:sub(i, i)
    local g = glyphs[ch]
    for r = 1, 3 do
      if ch == ':' and g[r] ~= ' ' then
        local len = 0
        for _, part in ipairs(rows[r]) do
          len = len + #part
        end
        table.insert(colon_offsets, { r, len })
      end
      table.insert(rows[r], g[r])
      if i < #time_str then
        table.insert(rows[r], ' ')
      end
    end
  end
  local out = {}
  for r = 1, 3 do
    out[r] = table.concat(rows[r])
  end
  return out, colon_offsets
end

-- Every non-space logo char becomes an animatable cell (x = display column).
local function build_logo()
  local cells, width = {}, 0
  for r, line in ipairs(logo) do
    local i, x = 1, 0
    while i <= #line do
      local len = line:byte(i) < 0x80 and 1 or 3
      x = x + 1
      if len == 3 and line:sub(i, i + 2) ~= '⠀' then
        table.insert(cells, { r = r, x = x, off = i - 1, kind = logo_map[r]:sub(x, x) })
      end
      i = i + len
    end
    width = math.max(width, x)
  end
  return logo, cells, width
end

local function get_plugin_info()
  if state and state.plugin_info then
    return state.plugin_info
  end
  local total, active = 0, 0
  if vim.pack and vim.pack.get then
    -- info = false: the default runs git for every plugin (~80ms)
    local plugins = vim.pack.get(nil, { info = false })
    total = #plugins
    for _, p in ipairs(plugins) do
      if p.active then
        active = active + 1
      end
    end
  end
  return string.format('load %d/%d plugins in %.2fms', active, total, vim.g.nvim_startup_time or 0)
end

-- Builds buffer lines plus the geometry needed by the animation.
local bc = { tl = '╭', tr = '╮', bl = '╰', br = '╯', h = '─', v = '│' }

local function layout(win)
  local W = config.inner_width
  local cols = vim.api.nvim_win_get_width(win)
  local height = vim.api.nvim_win_get_height(win)
  local frame = config.border and cols >= config.frame_min_columns
  local left = math.max(0, math.floor((cols - (W + 2)) / 2))
  local hl = config.highlights

  local time_str = os.date('%H:%M')
  local clock_rows, colon_offsets = build_clock(time_str)
  local _, clock_left = center(clock_rows[1], W)

  -- inner rows: { text, hls = { {c0, c1, group} }, tag }
  local inner = {}
  local function add(text, hls, tag)
    table.insert(inner, { text = text, hls = hls or {}, tag = tag })
  end

  add('')
  -- the clock is dropped on short windows so the logo and menu still fit
  if height >= config.clock_min_height then
    for r = 1, 3 do
      local text, l = center(clock_rows[r], W)
      add(text, { { l, l + #clock_rows[r], hl.clock } }, r == 1 and 'clock' or nil)
    end
    local date = os.date('%A · %d %b %Y')
    local date_text, date_left = center(date, W)
    add(date_text, { { date_left, date_left + #date, hl.date } })
    add('')
  end

  add('')
  local logo_rows, logo_cells, logo_width = build_logo()
  local _, logo_left = center(logo_rows[1], W)
  for r = 1, #logo_rows do
    local text, l = center(logo_rows[r], W)
    add(text, {}, 'logo' .. r)
  end
  add('')

  -- shortcuts laid out as a horizontal grid, config.menu_columns per row
  local ncols = config.menu_columns
  local items, col_w = {}, {}
  for i, s in ipairs(config.shortcuts) do
    items[i] = string.format('[%s]  %s', s.key, s.desc)
    local c = (i - 1) % ncols + 1
    col_w[c] = math.max(col_w[c] or 0, #items[i])
  end
  local gap = 2
  local block_width = gap * (math.min(ncols, #items) - 1)
  for _, w in ipairs(col_w) do
    block_width = block_width + w
  end
  local block_left = math.max(0, math.floor((W - block_width) / 2))
  for first = 1, #items, ncols do
    local text, hls = string.rep(' ', block_left), {}
    for c = 1, ncols do
      local item = items[first + c - 1]
      if not item then
        break
      end
      local off = #text
      table.insert(hls, { off + 1, off + 2, hl.key })
      table.insert(hls, { off + 5, off + #item, hl.desc })
      text = text .. item .. string.rep(' ', col_w[c] - #item + gap)
    end
    add((text:gsub('%s+$', '')), hls, first == 1 and 'first_shortcut' or nil)
  end

  add('')
  local info = get_plugin_info()
  local info_text, info_left = center(info, W)
  add(info_text, { { info_left, info_left + #info, hl.footer } })
  add('')

  local total = #inner + (frame and 2 or 0)
  local top = math.max(0, math.floor((height - total) / 2))

  local lines, highlights = {}, {}
  for _ = 1, top do
    table.insert(lines, '')
  end

  local lead = string.rep(' ', left)
  local ring, colon_cells, logo_path = {}, {}, {}
  local cursor

  if frame then
    table.insert(lines, lead .. bc.tl .. string.rep(bc.h, W) .. bc.tr)
    table.insert(highlights, { #lines - 1, left, #lines[#lines], hl.border })
    for j = 0, W + 1 do
      table.insert(ring, { row = #lines - 1, col = left + j * 3 })
    end
  end

  local right_cells, left_cells = {}, {}
  for _, row in ipairs(inner) do
    local pad_right = string.rep(' ', math.max(0, W - vim.fn.strdisplaywidth(row.text)))
    local base = #lead + (frame and 3 or 0)
    table.insert(
      lines,
      lead .. (frame and bc.v or '') .. row.text .. pad_right .. (frame and bc.v or '')
    )
    local lnum = #lines - 1

    if frame then
      local rcol = base + #row.text + #pad_right
      table.insert(highlights, { lnum, left, left + 3, hl.border })
      table.insert(highlights, { lnum, rcol, rcol + 3, hl.border })
      table.insert(left_cells, { row = lnum, col = left })
      table.insert(right_cells, { row = lnum, col = rcol })
    end

    for _, h in ipairs(row.hls) do
      table.insert(highlights, { lnum, base + h[1], base + h[2], h[3] })
    end

    if row.tag == 'clock' then
      for _, c in ipairs(colon_offsets) do
        table.insert(colon_cells, { row = lnum + c[1] - 1, col = base + clock_left + c[2] })
      end
    elseif row.tag and row.tag:match('^logo%d+$') then
      local r = tonumber(row.tag:sub(5))
      for _, c in ipairs(logo_cells) do
        if c.r == r then
          table.insert(
            logo_path,
            { x = c.x, r = r, kind = c.kind, row = lnum, col = base + logo_left + c.off }
          )
        end
      end
    elseif row.tag == 'first_shortcut' then
      cursor = { lnum + 1, base + block_left + 1 }
    end
  end

  if frame then
    table.insert(lines, lead .. bc.bl .. string.rep(bc.h, W) .. bc.br)
    table.insert(highlights, { #lines - 1, left, #lines[#lines], hl.border })

    -- clockwise ring: top (already added), right side, bottom, left side
    for _, c in ipairs(right_cells) do
      table.insert(ring, c)
    end
    for j = W + 1, 0, -1 do
      table.insert(ring, { row = #lines - 1, col = left + j * 3 })
    end
    for i = #left_cells, 1, -1 do
      table.insert(ring, left_cells[i])
    end
  end

  -- the dot snakes column by column, alternating up/down
  table.sort(logo_path, function(a, b)
    if a.x ~= b.x then
      return a.x < b.x
    end
    if a.x % 2 == 0 then
      return a.r < b.r
    end
    return a.r > b.r
  end)

  return {
    lines = lines,
    highlights = highlights,
    ring = ring,
    logo_path = logo_path,
    logo_width = logo_width,
    logo_rows = #logo_rows,
    colons = colon_cells,
    cursor = cursor,
    time = time_str,
  }
end

local function render(buf, set_cursor)
  local win = vim.fn.bufwinid(buf)
  if win == -1 then
    return
  end

  state.plugin_info = state.plugin_info or get_plugin_info()
  local geo = layout(win)
  state.geo = geo
  state.time = geo.time

  vim.bo[buf].modifiable = true
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, geo.lines)
  vim.bo[buf].modifiable = false

  vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
  for _, h in ipairs(geo.highlights) do
    vim.api.nvim_buf_set_extmark(
      buf,
      ns,
      h[1],
      h[2],
      { end_col = h[3], hl_group = h[4], priority = 100 }
    )
  end

  if set_cursor and geo.cursor then
    vim.api.nvim_win_set_cursor(win, geo.cursor)
  end
end

local function animate(buf)
  local geo = state.geo
  local tick = state.tick
  local hl = config.highlights

  vim.api.nvim_buf_clear_namespace(buf, ns_anim, 0, -1)

  local n = #geo.ring
  if n > 0 then
    local head = tick % n
    for i = 0, config.ring_tail - 1 do
      local cell = geo.ring[(head - i) % n + 1]
      vim.api.nvim_buf_set_extmark(buf, ns_anim, cell.row, cell.col, {
        end_col = cell.col + 3,
        hl_group = hl.ring[i + 1],
        priority = 200,
      })
    end
  end

  -- logo: a bright dot walks the path; cells it has passed turn rainbow,
  -- then the finished rainbow flows for a while before resetting
  local path = geo.logo_path
  local total = #path
  if total > 0 then
    local sweep = math.ceil(total / config.logo_step)
    local t = tick % (sweep + config.logo_hold_ticks)
    local reached = t < sweep and math.min(total, t * config.logo_step) or total
    local steps = config.rainbow_steps
    local shift = math.floor(tick / 2)
    for i = reached + 1, total do
      local c = path[i]
      local shade = math.min(4, math.floor((c.r - 1) / geo.logo_rows * 4) + 1)
      vim.api.nvim_buf_set_extmark(buf, ns_anim, c.row, c.col, {
        end_col = c.col + 3,
        hl_group = hl.logo_color .. c.kind:upper() .. shade,
        priority = 200,
      })
    end
    for i = 1, reached do
      local c = path[i]
      local idx = (math.floor(c.x / geo.logo_width * steps) + shift) % steps + 1
      vim.api.nvim_buf_set_extmark(buf, ns_anim, c.row, c.col, {
        end_col = c.col + 3,
        hl_group = hl.rainbow .. idx,
        priority = 200,
      })
    end
    if t < sweep then
      for i = math.max(1, reached - 1), reached do
        local c = path[i]
        vim.api.nvim_buf_set_extmark(buf, ns_anim, c.row, c.col, {
          end_col = c.col + 3,
          hl_group = hl.logo_head,
          priority = 210,
        })
      end
    end
  end

  if math.floor(tick / 10) % 2 == 1 then
    for _, c in ipairs(geo.colons) do
      vim.api.nvim_buf_set_extmark(buf, ns_anim, c.row, c.col, {
        virt_text = { { ' ', hl.clock } },
        virt_text_pos = 'overlay',
        priority = 200,
      })
    end
  end
end

-- Stops `timer` (default: the current dashboard's timer). Callers that own a
-- specific timer pass it in, so they can never stop another dashboard's timer.
local function stop_timer(timer)
  timer = timer or (state and state.timer)
  if timer and not timer:is_closing() then
    timer:stop()
    timer:close()
  end
  if state and state.timer == timer then
    state.timer = nil
  end
end

local function start_timer(buf)
  local timer = vim.uv.new_timer()
  state.timer = timer
  timer:start(
    0,
    config.tick_ms,
    vim.schedule_wrap(function()
      -- a tick queued before the timer was stopped can still arrive here
      if timer:is_closing() then
        return
      end
      if not state or state.buf ~= buf or not vim.api.nvim_buf_is_valid(buf) then
        return stop_timer(timer)
      end
      if vim.fn.bufwinid(buf) == -1 or not state.geo then
        return
      end
      state.tick = state.tick + 1
      -- refresh the clock when the minute rolls over (checked once a second)
      if state.tick % 20 == 0 and os.date('%H:%M') ~= state.time then
        render(buf, false)
      end
      animate(buf)
    end)
  )
end

-- Reuses the current buffer only when it is the untouched startup buffer;
-- anything else (a real file, an empty named buffer, an old dashboard) is
-- left alone and a fresh scratch buffer is created instead.
local function create_dashboard_buffer()
  local cur = vim.api.nvim_get_current_buf()
  local reusable = vim.api.nvim_buf_get_name(cur) == ''
    and vim.bo[cur].buftype == ''
    and not vim.bo[cur].modified
    and vim.fn.line2byte('$') == -1
  local buf = reusable and cur or vim.api.nvim_create_buf(false, true)
  vim.bo[buf].bufhidden = 'wipe'
  vim.bo[buf].buftype = 'nofile'
  vim.bo[buf].buflisted = false
  vim.bo[buf].swapfile = false
  vim.bo[buf].modifiable = false
  return buf
end

local function setup_keymaps(buf)
  local opts = { noremap = true, silent = true, buffer = buf }

  -- defaults first, so a shortcut in config can take over the same key
  vim.keymap.set('n', '<Esc>', ':q<CR>', opts)
  vim.keymap.set('n', 'q', ':q<CR>', opts)

  for _, shortcut in ipairs(config.shortcuts) do
    vim.keymap.set('n', shortcut.key, shortcut.action, opts)
  end
end

local window_opts = {
  'number',
  'relativenumber',
  'cursorline',
  'cursorcolumn',
  'colorcolumn',
  'signcolumn',
  'wrap',
  'listchars',
}

-- Saves the options of `win` and returns a function that restores them on that
-- same window, whichever window happens to be current when it runs.
local function opt_handler(win)
  local saved = {}
  for _, name in ipairs(window_opts) do
    saved[name] = vim.wo[win][name]
  end
  local showtabline = vim.o.showtabline

  return function()
    if vim.api.nvim_win_is_valid(win) then
      for name, value in pairs(saved) do
        vim.wo[win][name] = value
      end
    end
    vim.o.laststatus = 2
    vim.o.showtabline = showtabline
  end
end

function M.setup(opts)
  config = vim.tbl_deep_extend('force', config, opts or {})
end

-- force = true (used by :Dashboard) skips the "only on an empty startup" check.
function M.show(force)
  if not force and (vim.fn.argc() > 0 or vim.fn.line2byte('$') ~= -1) then
    vim.o.laststatus = 2
    return
  end

  stop_timer()
  local win = vim.api.nvim_get_current_win()
  local buf = create_dashboard_buffer()
  -- if an older dashboard is in this window, its BufWinLeave runs here and
  -- restores the window before the options below are saved
  vim.api.nvim_win_set_buf(win, buf)
  vim.bo[buf].filetype = 'dashboard'
  state = { buf = buf, tick = 0 }

  setup_highlights()
  setup_keymaps(buf)

  local restore_opt = opt_handler(win)

  local wo = vim.wo[win]
  wo.number = false
  wo.relativenumber = false
  wo.cursorline = false
  wo.cursorcolumn = false
  wo.colorcolumn = '0'
  wo.signcolumn = 'no'
  wo.wrap = false
  wo.listchars = 'precedes: '

  vim.o.laststatus = 0
  vim.o.showtabline = 0

  render(buf, true)
  start_timer(buf)

  -- WinResized covers split resizes, VimResized the terminal itself
  vim.api.nvim_create_autocmd({ 'VimResized', 'WinResized' }, {
    group = group,
    callback = function()
      if not state or state.buf ~= buf or not vim.api.nvim_buf_is_valid(buf) then
        return true -- this dashboard is gone: delete the autocmd
      end
      if vim.fn.bufwinid(buf) ~= -1 then
        render(buf, true)
      end
    end,
  })

  -- BufWinLeave (unlike BufLeave) does not fire when a float such as FzfLua
  -- opens on top, so the animation keeps running and the options stay put
  -- until the dashboard really leaves its window.
  vim.api.nvim_create_autocmd('BufWinLeave', {
    buffer = buf,
    group = group,
    callback = function()
      if state and state.buf == buf then
        stop_timer()
      end
      restore_opt()
    end,
  })

  vim.api.nvim_create_autocmd({ 'BufWipeout', 'BufUnload' }, {
    buffer = buf,
    group = group,
    callback = function()
      if state and state.buf == buf then
        stop_timer()
      end
    end,
  })
end

vim.api.nvim_create_autocmd('ColorScheme', {
  group = group,
  callback = setup_highlights,
})

vim.api.nvim_create_autocmd('VimEnter', {
  group = group,
  callback = function()
    if vim.fn.argc() == 0 and vim.fn.line2byte('$') == -1 then
      M.show()
    else
      vim.o.laststatus = 2
    end
  end,
})

vim.api.nvim_create_user_command('Dashboard', function()
  M.show(true)
end, {})

return M
