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
    { key = 'e', desc = 'New  File', action = '<cmd>enew<CR>' },
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

  -- logo animation:
  --   'snake'   a white dot snakes through the logo leaving a rainbow behind
  --   'wave'    a diagonal rainbow flows across the logo
  --   'shine'   a slanted glare sweeps over the logo colours
  --   'ripple'  rings of light spread out from the centre
  --   'breathe' the logo slowly brightens and dims, top to bottom
  --   'spiral'  a rotating rainbow colour wheel, wound into a spiral
  --   'radial'  rainbow rings flowing out of the centre
  --   'tricolor' each of the three parts gets its own hue, all cycling
  --   'rise'    rainbow liquid fills the logo from the bottom, then drains
  --   'rain'    matrix-style drops fall down every column
  --   'dissolve' the logo appears cell by cell, holds, then vanishes
  --   'plasma'  demoscene plasma: overlapping sine waves of colour
  --   'firework' rainbow shock waves burst from random points of a dimmed logo
  --   'glitch'  calm logo hit by short bursts of torn, colour-shifted rows
  --   'heartbeat' a lub-dub double pulse radiating from the centre
  --   'none'    static logo colours
  -- 'random' picks a different effect every round; a list such as
  -- { 'snake', 'shine', 'ripple' } plays them in turn.
  logo_effect = 'random',
  logo_effect_ticks = 200, -- round length (cycling) for effects without a natural one
  logo_glow_levels = 3, -- shades between a logo colour and white
  logo_dim = 0.6, -- firework: how far the logo fades towards the background
  logo_step = 3, -- snake: logo cells the dot travels per tick
  logo_hold_ticks = 120, -- snake: how long the finished rainbow keeps flowing
  shine_width = 6, -- shine: half width of the glare band, in columns
  shine_pause = 60, -- shine: ticks between two sweeps
  ripple_spacing = 14, -- ripple: distance between two rings
  firework_gap = 20, -- firework: average ticks between two bursts
  heartbeat_ticks = 24, -- heartbeat: ticks per beat (24 * 50ms = 50 bpm)
  minute_shine = true, -- sweep a shine over any effect when the minute changes
  spiral_twist = 0.4, -- spiral: how far the colour wheel winds, 0 = plain wheel
  rise_ticks = 60, -- rise: ticks to fill (and to drain) the logo
  rain_tail = 5, -- rain: drop length in rows
  dissolve_ticks = 50, -- dissolve: ticks for the logo to appear (and to vanish)
  dissolve_hold = 120, -- dissolve: ticks the complete logo stays
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
    -- suffixed with kind (B/C/R) and shade 1..4, plus 'Glow' .. level for the light shades
    logo_color = 'DashboardLogo',
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

-- mixes two '#rrggbb' colours, t = 0 -> a, t = 1 -> b
local function blend(a, b, t)
  local out = {}
  for _, i in ipairs({ 2, 4, 6 }) do
    local ca, cb = tonumber(a:sub(i, i + 1), 16), tonumber(b:sub(i, i + 1), 16)
    table.insert(out, math.floor(ca * (1 - t) + cb * t + 0.5))
  end
  return string.format('#%02x%02x%02x', out[1], out[2], out[3])
end

local function setup_highlights()
  local hl = config.highlights
  local steps = config.rainbow_steps
  for i = 1, steps do
    local hue = (i - 1) / steps * 360
    vim.api.nvim_set_hl(0, hl.rainbow .. i, { fg = hsv_to_hex(hue, 0.55, 0.95), default = true })
  end
  vim.api.nvim_set_hl(0, hl.logo_head, { fg = '#ffffff', bold = true, default = true })

  -- background the dimmed logo fades into
  local ok, normal = pcall(vim.api.nvim_get_hl, 0, { name = 'Normal', link = false })
  local bg = ok and normal.bg and string.format('#%06x', normal.bg)
    or (vim.o.background == 'light' and '#ffffff' or '#000000')

  local levels = config.logo_glow_levels
  for kind, shades in pairs(config.logo_palette) do
    for i, color in ipairs(shades) do
      local name = hl.logo_color .. kind:upper() .. i
      vim.api.nvim_set_hl(0, name, { fg = color, default = true })
      vim.api.nvim_set_hl(
        0,
        name .. 'Dim',
        { fg = blend(color, bg, config.logo_dim), default = true }
      )
      for l = 1, levels do
        local glow = blend(color, '#ffffff', l / (levels + 1))
        vim.api.nvim_set_hl(0, name .. 'Glow' .. l, { fg = glow, default = true })
      end
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
  -- textoff = columns taken by number/sign/fold/statuscolumn, which are not text
  local info = vim.fn.getwininfo(win)[1]
  local cols = info.width - info.textoff
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
    local text = center(logo_rows[r], W)
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
  local plugin_info = get_plugin_info()
  local info_text, info_left = center(plugin_info, W)
  add(info_text, { { info_left, info_left + #plugin_info, hl.footer } })
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
      local shade = math.min(4, math.floor((r - 1) / #logo_rows * 4) + 1)
      for _, c in ipairs(logo_cells) do
        if c.r == r then
          table.insert(logo_path, {
            x = c.x,
            r = r,
            kind = c.kind,
            base = hl.logo_color .. c.kind:upper() .. shade, -- resting colour group
            row = lnum,
            col = base + logo_left + c.off,
          })
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

local function render(buf, reset_view)
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

  if reset_view then
    -- A narrow or short window scrolls the view (leftcol/topline) to keep the
    -- cursor visible; growing the window again keeps that offset, so the new,
    -- correctly centred lines would still show up shifted. Start from 1,0.
    vim.api.nvim_win_call(win, function()
      vim.fn.winrestview({ topline = 1, leftcol = 0 })
    end)
    if geo.cursor then
      vim.api.nvim_win_set_cursor(win, geo.cursor)
    end
  end
end

-- Logo effects. `draw(ctx)` paints every cell of ctx.path through ctx.put;
-- `period(ctx)` (optional) is the length of one natural round in ticks, used
-- when several effects take turns. ctx.t counts ticks since the effect started
-- and ctx.data is scratch space that lives as long as the effect.
local effects = {}

effects.none = {
  draw = function(ctx)
    for _, c in ipairs(ctx.path) do
      ctx.put(c, c.base)
    end
  end,
}

effects.snake = {
  period = function(ctx)
    return math.ceil(#ctx.path / config.logo_step) + config.logo_hold_ticks
  end,
  draw = function(ctx)
    local path, total = ctx.path, #ctx.path
    local sweep = math.ceil(total / config.logo_step)
    local t = ctx.t % (sweep + config.logo_hold_ticks)
    local reached = t < sweep and math.min(total, t * config.logo_step) or total
    local shift = math.floor(ctx.tick / 2)
    for i, c in ipairs(path) do
      if i <= reached then
        ctx.put(c, ctx.rainbow(math.floor(c.x / ctx.width * config.rainbow_steps) + shift))
      else
        ctx.put(c, c.base)
      end
    end
    if t < sweep then
      for i = math.max(1, reached - 1), reached do
        ctx.put(path[i], ctx.head, 210)
      end
    end
  end,
}

effects.wave = {
  draw = function(ctx)
    local span = ctx.width + ctx.rows * 2 -- a text row is about two columns tall
    local shift = math.floor(ctx.t / 2)
    for _, c in ipairs(ctx.path) do
      local pos = math.floor((c.x + c.r * 2) / span * config.rainbow_steps)
      ctx.put(c, ctx.rainbow(pos - shift))
    end
  end,
}

-- glare band along x + 1.2 * r, i.e. slanted like '/'
-- glow level of `c` inside a '/' slanted glare band centred at `pos` (0 = outside)
local function shine_level(c, pos)
  local w = config.shine_width
  local dist = math.abs(c.x + c.r * 1.2 - pos)
  return dist < w and math.ceil((1 - dist / w) * (config.logo_glow_levels + 1)) or 0
end

-- ticks one shine sweep takes to cross the logo
local function shine_length(ctx)
  return ctx.width + math.ceil(ctx.rows * 1.2) + 2 * config.shine_width
end

effects.shine = {
  period = function(ctx)
    return shine_length(ctx) + config.shine_pause
  end,
  draw = function(ctx)
    local pos = ctx.t % effects.shine.period(ctx) - config.shine_width
    for _, c in ipairs(ctx.path) do
      ctx.put(c, ctx.glow(c, shine_level(c, pos)))
    end
  end,
}

effects.ripple = {
  draw = function(ctx)
    local levels, spacing, tail = config.logo_glow_levels, config.ripple_spacing, 4
    local cx, cy = (ctx.width + 1) / 2, (ctx.rows + 1) / 2
    for _, c in ipairs(ctx.path) do
      local dist = math.sqrt((c.x - cx) ^ 2 + ((c.r - cy) * 2) ^ 2)
      -- 0 on the ring crest, growing towards the centre (the fading tail)
      local p = (ctx.t * 0.5 - dist) % spacing
      local level = p < tail and math.ceil((1 - p / tail) * (levels + 1)) or 0
      ctx.put(c, ctx.glow(c, level))
    end
  end,
}

effects.breathe = {
  draw = function(ctx)
    local levels = config.logo_glow_levels
    for _, c in ipairs(ctx.path) do
      local s = (1 - math.cos(ctx.t * 0.1 - c.r * 0.25)) / 2 -- 0..1, travels downwards
      ctx.put(c, ctx.glow(c, math.floor(s * levels + 0.5)))
    end
  end,
}

-- distance and angle of a cell from the logo centre (a text row counts as two columns)
local function polar(ctx, c)
  local dx = c.x - (ctx.width + 1) / 2
  local dy = (c.r - (ctx.rows + 1) / 2) * 2
  return math.sqrt(dx * dx + dy * dy), math.atan2(dy, dx)
end

effects.spiral = {
  draw = function(ctx)
    local steps = config.rainbow_steps
    local shift = math.floor(ctx.t / 2)
    for _, c in ipairs(ctx.path) do
      local dist, angle = polar(ctx, c)
      local pos = (angle / (2 * math.pi) + 0.5) * steps + dist * config.spiral_twist
      ctx.put(c, ctx.rainbow(math.floor(pos) - shift))
    end
  end,
}

effects.radial = {
  draw = function(ctx)
    local shift = math.floor(ctx.t / 2)
    for _, c in ipairs(ctx.path) do
      local dist = polar(ctx, c)
      ctx.put(c, ctx.rainbow(math.floor(dist * 0.8) - shift))
    end
  end,
}

local part_offset = { b = 0, c = 1 / 3, r = 2 / 3 }

effects.tricolor = {
  draw = function(ctx)
    local steps = config.rainbow_steps
    local shift = math.floor(ctx.t / 3)
    for _, c in ipairs(ctx.path) do
      local pos = (part_offset[c.kind] or 0) * steps + c.r * 0.5
      ctx.put(c, ctx.rainbow(math.floor(pos) + shift))
    end
  end,
}

effects.rise = {
  period = function()
    return 3 * config.rise_ticks -- fill, hold, drain
  end,
  draw = function(ctx)
    local fill, levels = config.rise_ticks, config.logo_glow_levels
    local t = ctx.t % (3 * fill)
    local p = t < fill and t / fill or (t < 2 * fill and 1 or (3 * fill - t) / fill)
    local surface = (ctx.rows + 1.5) - p * (ctx.rows + 2) -- row of the liquid surface
    local shift = math.floor(ctx.t / 2)
    for _, c in ipairs(ctx.path) do
      local level = surface + math.sin(c.x * 0.45 + ctx.t * 0.25) * 0.6
      if c.r >= level then
        -- horizontal rainbow bands drifting upwards
        ctx.put(c, ctx.rainbow(math.floor(c.r * 1.5) + shift))
      elseif c.r >= level - 1 then
        ctx.put(c, ctx.glow(c, levels)) -- light foam on top of the surface
      else
        ctx.put(c, c.base)
      end
    end
  end,
}

effects.rain = {
  draw = function(ctx)
    local levels, tail = config.logo_glow_levels, config.rain_tail
    local drops = ctx.data.drops or {}
    ctx.data.drops = drops
    local function spawn(first)
      return {
        -- the first drops start anywhere so the screen isn't empty at first
        y = first and math.random() * (ctx.rows + tail) - tail or -math.random() * ctx.rows,
        speed = 0.25 + math.random() * 0.5,
      }
    end
    for x = 1, ctx.width do
      local d = drops[x] or spawn(true)
      d.y = d.y + d.speed
      if d.y - tail > ctx.rows then
        d = spawn(false)
      end
      drops[x] = d
    end
    for _, c in ipairs(ctx.path) do
      local k = drops[c.x].y - c.r -- rows below the drop head
      local level = 0
      if k >= 0 and k < 1 then
        level = levels + 1
      elseif k >= 1 and k < tail then
        level = math.ceil((1 - k / tail) * levels)
      end
      ctx.put(c, ctx.glow(c, level))
    end
  end,
}

effects.dissolve = {
  period = function()
    return 2 * config.dissolve_ticks + config.dissolve_hold
  end,
  draw = function(ctx)
    local n, levels = #ctx.path, config.logo_glow_levels
    local span, hold = config.dissolve_ticks, config.dissolve_hold
    local order = ctx.data.order
    if not order or #order ~= n then
      -- order[i] = when cell i shows up: a random permutation of 1..n
      order = {}
      for i = 1, n do
        order[i] = i
      end
      for i = n, 2, -1 do
        local j = math.random(i)
        order[i], order[j] = order[j], order[i]
      end
      ctx.data.order = order
    end

    local t = ctx.t % (2 * span + hold)
    local shown, appearing
    if t < span then
      shown, appearing = t / span * n, true
    elseif t < span + hold then
      shown = n
    else
      shown = (1 - (t - span - hold) / span) * n
    end

    for i, c in ipairs(ctx.path) do
      if order[i] > shown then
        ctx.hide(c)
      else
        -- freshly appeared cells flash white and settle back to their colour
        local age = appearing and (shown - order[i]) / n * span or math.huge
        ctx.put(c, ctx.glow(c, levels + 1 - math.floor(age)))
      end
    end
  end,
}

effects.plasma = {
  draw = function(ctx)
    local steps, t = config.rainbow_steps, ctx.t * 0.08
    for _, c in ipairs(ctx.path) do
      local x, y = c.x, c.r * 2
      local dist = polar(ctx, c)
      -- four interfering waves, each in [-1, 1]
      local v = math.sin(x * 0.22 + t)
        + math.sin(y * 0.18 - t * 0.7)
        + math.sin((x + y) * 0.15 + t * 0.5)
        + math.sin(dist * 0.3 - t * 1.3)
      ctx.put(c, ctx.rainbow(math.floor((v + 4) / 8 * steps * 1.5)))
    end
  end,
}

effects.firework = {
  draw = function(ctx)
    local d = ctx.data
    local speed, thick, gap = 0.9, 3, config.firework_gap
    d.bursts = d.bursts or {}
    d.next = d.next or 0

    if ctx.t >= d.next then
      local origin = ctx.path[math.random(#ctx.path)] -- bursts start on the logo itself
      table.insert(d.bursts, {
        x = origin.x,
        y = origin.r * 2,
        born = ctx.t,
        hue = math.random(config.rainbow_steps),
      })
      d.next = ctx.t + math.random(math.floor(gap / 2), math.ceil(gap * 1.5))
    end
    -- a shock wave is gone once it has left the logo
    local reach = math.sqrt(ctx.width ^ 2 + (ctx.rows * 2) ^ 2) + thick
    for i = #d.bursts, 1, -1 do
      if (ctx.t - d.bursts[i].born) * speed > reach then
        table.remove(d.bursts, i)
      end
    end

    for _, c in ipairs(ctx.path) do
      local group = ctx.dim(c)
      for _, b in ipairs(d.bursts) do -- newer bursts are drawn over older ones
        local dist = math.sqrt((c.x - b.x) ^ 2 + (c.r * 2 - b.y) ^ 2)
        local k = (ctx.t - b.born) * speed - dist -- depth behind the wave front
        if k >= 0 and k < 1 then
          group = ctx.head -- white leading edge
        elseif k >= 1 and k < thick then
          group = ctx.rainbow(b.hue + math.floor(dist * 0.5))
        end
      end
      ctx.put(c, group)
    end
  end,
}

effects.glitch = {
  draw = function(ctx)
    local d = ctx.data
    local levels = config.logo_glow_levels
    d.next = d.next or 20

    if ctx.t >= d.next then
      d.start = ctx.t
      d.stop = ctx.t + math.random(3, 8)
      d.next = d.stop + math.random(15, 50)
    end
    local active = d.stop and ctx.t < d.stop

    if not active then
      d.rows = nil
    elseif not d.rows or math.random() < 0.5 then
      -- a few horizontal bands; re-rolled on most ticks so it jitters
      d.rows = {}
      for _ = 1, math.random(2, 4) do
        local band = {
          hue = math.random(config.rainbow_steps),
          gap = math.random(3, 6),
          shift = math.random(0, 5),
        }
        local first = math.random(ctx.rows)
        for r = first, math.min(ctx.rows, first + math.random(0, 2)) do
          d.rows[r] = band
        end
      end
    end

    for _, c in ipairs(ctx.path) do
      local band = d.rows and d.rows[c.r]
      if active and ctx.t == d.start then
        ctx.put(c, ctx.glow(c, levels)) -- a flash as the glitch hits
      elseif not band then
        ctx.put(c, c.base)
      elseif (c.x + band.shift) % band.gap == 0 then
        ctx.hide(c) -- torn gaps
      else
        ctx.put(c, ctx.rainbow(band.hue + math.floor(c.x / 4)))
      end
    end
  end,
}

effects.heartbeat = {
  period = function()
    return config.heartbeat_ticks * 4
  end,
  draw = function(ctx)
    local levels, beat = config.logo_glow_levels, config.heartbeat_ticks
    -- a sharp pulse that decays over a few ticks
    local function pulse(x)
      return x >= 0 and math.exp(-x / 2.5) or 0
    end
    for _, c in ipairs(ctx.path) do
      -- the beat reaches the edges a little later than the centre
      local t = (ctx.t - polar(ctx, c) * 0.15) % beat
      local a = pulse(t) + 0.7 * pulse(t - 5) -- lub ... dub
      if a < 0.08 then
        ctx.put(c, ctx.dim(c)) -- resting between beats
      elseif a < 0.25 then
        ctx.put(c, c.base)
      else
        ctx.put(c, ctx.glow(c, math.ceil((a - 0.25) / 0.75 * (levels + 1))))
      end
    end
  end,
}

-- effects 'random' chooses from
local effect_names = {
  'snake',
  'wave',
  'shine',
  'ripple',
  'breathe',
  'spiral',
  'radial',
  'tricolor',
  'rise',
  'rain',
  'dissolve',
  'plasma',
  'firework',
  'glitch',
  'heartbeat',
}

local function rotating()
  local opt = config.logo_effect
  return opt == 'random' or (type(opt) == 'table' and #opt > 1)
end

local function new_fx(prev, tick)
  local opt = config.logo_effect
  local name, index
  if opt == 'random' then
    index = math.random(#effect_names)
    if prev and effect_names[index] == prev.name then
      index = index % #effect_names + 1
    end
    name = effect_names[index]
  elseif type(opt) == 'table' then
    index = prev and (prev.index % #opt + 1) or 1
    name = opt[index]
  else
    name, index = opt, 1
  end
  if not effects[name] then
    name = 'snake'
  end
  return { name = name, index = index, start = tick, data = {} }
end

local function animate_logo(buf, geo, tick)
  local path = geo.logo_path
  if #path == 0 then
    return
  end
  local hl = config.highlights
  local levels = config.logo_glow_levels

  local ctx = {
    path = path,
    width = geo.logo_width,
    rows = geo.logo_rows,
    tick = tick,
    head = hl.logo_head,
  }
  function ctx.put(c, group, priority)
    vim.api.nvim_buf_set_extmark(buf, ns_anim, c.row, c.col, {
      end_col = c.col + 3,
      hl_group = group,
      priority = priority or 200,
    })
  end
  -- covers the cell with a blank, as if it weren't there
  function ctx.hide(c)
    vim.api.nvim_buf_set_extmark(buf, ns_anim, c.row, c.col, {
      virt_text = { { ' ' } },
      virt_text_pos = 'overlay',
      priority = 200,
    })
  end
  function ctx.rainbow(i)
    return hl.rainbow .. (i % config.rainbow_steps + 1)
  end
  -- 0 = resting colour, 1..levels = lighter shades, above that = white
  function ctx.glow(c, level)
    if level <= 0 then
      return c.base
    elseif level > levels then
      return hl.logo_head
    end
    return c.base .. 'Glow' .. level
  end
  function ctx.dim(c)
    return c.base .. 'Dim'
  end

  local fx = state.fx or new_fx(nil, tick)
  local effect = effects[fx.name]
  if rotating() then
    local length = effect.period and effect.period(ctx) or config.logo_effect_ticks
    if tick - fx.start >= length then
      fx = new_fx(fx, tick)
      effect = effects[fx.name]
    end
  end
  state.fx = fx

  ctx.t = tick - fx.start
  ctx.data = fx.data
  effect.draw(ctx)

  -- one shine sweep over whatever effect is running, when the minute changes
  if config.minute_shine and state.shine_at then
    local t = tick - state.shine_at
    if t >= shine_length(ctx) then
      state.shine_at = nil
    else
      local pos = t - config.shine_width
      for _, c in ipairs(path) do
        local level = shine_level(c, pos)
        if level > 0 then
          ctx.put(c, ctx.glow(c, level), 205)
        end
      end
    end
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

  animate_logo(buf, geo, tick)

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
        state.shine_at = state.tick
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
  'scrolloff',
  'sidescrolloff',
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

  local fx = config.logo_effect
  for _, name in ipairs(type(fx) == 'table' and fx or { fx }) do
    if name ~= 'random' and not effects[name] then
      vim.notify(
        ('dashboard: unknown logo_effect %q, using "snake"'):format(tostring(name)),
        vim.log.levels.WARN
      )
    end
  end
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
  -- a big global 'scrolloff' (e.g. 999) would keep the cursor line in the
  -- middle of the window and push the whole dashboard off centre
  wo.scrolloff = 0
  wo.sidescrolloff = 0

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
        -- repaint now so the old animation marks don't flash at stale positions
        animate(buf)
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
