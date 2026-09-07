local api, uv = vim.api, vim.uv
local M = {}

local config = {
  width = math.floor(vim.o.columns * 0.15),
  height = math.floor(vim.o.lines * 0.5),
  block_size = 2,
}

local state = {
  board = {},
  board_colors = {},
  current_piece = nil,
  current_x = 0,
  current_y = 0,
  ns_id = nil,
  score = 0,
  game_over = false,
  win = nil,
  buf = nil,
  timer = nil,
  speed = 500,
}

local pieces = {
  I = {
    shapes = {
      { 0b1111 }, -- ████
      { 0b1, 0b1, 0b1, 0b1 }, -- █ █ █ █
    },
    color = 'TetrisI',
    width = { 4, 1 },
    height = { 1, 4 },
  },
  O = {
    shapes = {
      { 0b11, 0b11 }, -- ██
      -- ██
    },
    color = 'TetrisO',
    width = { 2 },
    height = { 2 },
  },
  T = {
    shapes = {
      { 0b010, 0b111 }, -- ·█
      -- ███
      { 0b10, 0b11, 0b10 }, -- █
      -- ██
      -- █
      { 0b111, 0b010 }, -- ███
      -- ·█
      { 0b01, 0b11, 0b01 }, -- ·█
      -- ██
      -- ·█
    },
    color = 'TetrisT',
    width = { 3, 2, 3, 2 },
    height = { 2, 3, 2, 3 },
  },
  S = {
    shapes = {
      { 0b011, 0b110 }, -- ·██
      -- ██
      { 0b10, 0b11, 0b01 }, -- █
      -- ██
      -- ·█
    },
    color = 'TetrisS',
    width = { 3, 2 },
    height = { 2, 3 },
  },
  Z = {
    shapes = {
      { 0b110, 0b011 }, -- ██
      -- ·██
      { 0b01, 0b11, 0b10 }, -- ·█
      -- ██
      -- █
    },
    color = 'TetrisZ',
    width = { 3, 2 },
    height = { 2, 3 },
  },
  J = {
    shapes = {
      { 0b100, 0b111 }, -- █
      -- ███
      { 0b11, 0b10, 0b10 }, -- ██
      -- █·
      -- █·
      { 0b111, 0b001 }, -- ███
      -- ··█
      { 0b01, 0b01, 0b11 }, -- ·█
      -- ·█
      -- ██
    },
    color = 'TetrisJ',
    width = { 3, 2, 3, 2 },
    height = { 2, 3, 2, 3 },
  },
  L = {
    shapes = {
      { 0b001, 0b111 }, -- ··█
      -- ███
      { 0b10, 0b10, 0b11 }, -- █
      -- █·
      -- ██
      { 0b111, 0b100 }, -- ███
      -- █
      { 0b11, 0b01, 0b01 }, -- ██
      -- ·█
      -- ·█
    },
    color = 'TetrisL',
    width = { 3, 2, 3, 2 },
    height = { 2, 3, 2, 3 },
  },
}

local function setup_highlights()
  api.nvim_set_hl(0, 'TetrisI', { bg = '#00f0f0', fg = '#000000' })
  api.nvim_set_hl(0, 'TetrisO', { bg = '#f0f000', fg = '#000000' })
  api.nvim_set_hl(0, 'TetrisT', { bg = '#a000f0', fg = '#000000' })
  api.nvim_set_hl(0, 'TetrisS', { bg = '#00f000', fg = '#000000' })
  api.nvim_set_hl(0, 'TetrisZ', { bg = '#f00000', fg = '#000000' })
  api.nvim_set_hl(0, 'TetrisJ', { bg = '#0000f0', fg = '#000000' })
  api.nvim_set_hl(0, 'TetrisL', { bg = '#f0a000', fg = '#000000' })
  api.nvim_set_hl(0, 'TetrisBorder', { bg = '#808080', fg = '#000000' })
  api.nvim_set_hl(0, 'TetrisEmpty', { bg = '#1a1a1a', fg = '#1a1a1a' })
end

local function init_board()
  state.board = {}
  state.board_colors = {}
  for y = 1, config.height do
    state.board[y] = 0 -- empty line
    state.board_colors[y] = {}
  end
end

local function is_valid_position(piece, x, y)
  local shape = piece.shape
  local width = piece.width
  local height = piece.height

  if x < 1 or x + width - 1 > config.width then
    return false
  end

  if y < 1 or y + height - 1 > config.height then
    return false
  end

  -- collision detection
  for i, row_bits in ipairs(shape) do
    local board_y = y + i - 1
    if board_y >= 1 and board_y <= config.height then
      local shift = config.width - x - width + 1
      local shifted_row = bit.lshift(row_bits, shift)

      if bit.band(state.board[board_y], shifted_row) ~= 0 then
        return false
      end
    end
  end

  return true
end

local function spawn_piece()
  local piece_names = { 'I', 'O', 'T', 'S', 'Z', 'J', 'L' }
  local name = piece_names[math.random(#piece_names)]
  local piece = pieces[name]

  state.current_piece = {
    name = name,
    shape = piece.shapes[1],
    color = piece.color,
    rotation = 1,
    width = piece.width[1],
    height = piece.height[1],
  }

  state.current_x = math.floor((config.width - state.current_piece.width) / 2) + 1
  state.current_y = 1

  if not is_valid_position(state.current_piece, state.current_x, state.current_y) then
    state.game_over = true
  end
end

local function lock_piece()
  local piece = state.current_piece
  local shape = piece.shape
  local x = state.current_x
  local y = state.current_y
  local width = piece.width

  for i, row_bits in ipairs(shape) do
    local board_y = y + i - 1
    if board_y >= 1 and board_y <= config.height then
      local shift = config.width - x - width + 1
      local shifted_row = bit.lshift(row_bits, shift)
      state.board[board_y] = bit.bor(state.board[board_y], shifted_row)

      for j = 0, width - 1 do
        if bit.band(row_bits, bit.lshift(1, width - 1 - j)) ~= 0 then
          state.board_colors[board_y][x + j] = piece.color
        end
      end
    end
  end
end

local function clear_lines()
  local lines_cleared = 0
  local full_line = bit.lshift(1, config.width) - 1

  for y = config.height, 1, -1 do
    if state.board[y] == full_line then
      lines_cleared = lines_cleared + 1
      table.remove(state.board, y)
      table.remove(state.board_colors, y)
      table.insert(state.board, 1, 0)
      table.insert(state.board_colors, 1, {})
    end
  end

  if lines_cleared > 0 then
    local score_table = {
      [1] = 100, -- single
      [2] = 300, -- double
      [3] = 500, -- thriple
      [4] = 800, -- four
    }
    state.score = state.score + (score_table[lines_cleared] or 0)
    -- improve speed
    state.speed = math.max(100, state.speed - lines_cleared * 10)
  end

  return lines_cleared
end

local function render()
  if not state.buf or not vim.api.nvim_buf_is_valid(state.buf) then
    return
  end

  local lines = {}
  local highlights = {}

  local render_board = {}
  local render_colors = {}

  for y = 1, config.height do
    render_board[y] = state.board[y]
    render_colors[y] = vim.deepcopy(state.board_colors[y])
  end

  if state.current_piece and not state.game_over then
    local piece = state.current_piece
    local x = state.current_x
    local y = state.current_y
    local width = piece.width

    for i, row_bits in ipairs(piece.shape) do
      local board_y = y + i - 1
      if board_y >= 1 and board_y <= config.height then
        local shift = config.width - x - width + 1
        local shifted_row = bit.lshift(row_bits, shift)
        render_board[board_y] = bit.bor(render_board[board_y], shifted_row)

        for j = 0, width - 1 do
          if bit.band(row_bits, bit.lshift(1, width - 1 - j)) ~= 0 then
            render_colors[board_y][x + j] = piece.color
          end
        end
      end
    end
  end

  for y = 1, config.height do
    local line = ''
    for x = 1, config.width do
      local has_block = bit.band(render_board[y], bit.lshift(1, config.width - x)) ~= 0
      local chars = string.rep('  ', 1)
      line = line .. chars

      if has_block then
        local color = render_colors[y][x] or 'TetrisEmpty'
        table.insert(highlights, {
          line = #lines,
          col_start = (x - 1) * config.block_size,
          col_end = x * config.block_size,
          hl_group = color,
        })
      else
        table.insert(highlights, {
          line = #lines,
          col_start = (x - 1) * config.block_size,
          col_end = x * config.block_size,
          hl_group = 'TetrisEmpty',
        })
      end
    end
    table.insert(lines, line)
  end

  table.insert(lines, '')
  table.insert(lines, string.format('Score: %d', state.score))
  table.insert(lines, string.format('Speed: %dms', state.speed))
  table.insert(lines, '')
  table.insert(lines, 'Scoring:')
  table.insert(lines, 'Single: 100  Double: 300')
  table.insert(lines, 'Triple: 500  Tetris: 800')
  table.insert(lines, '')
  table.insert(lines, 'Controls:')
  table.insert(lines, '← → h l : Move')
  table.insert(lines, '↑ k     : Rotate')
  table.insert(lines, '↓ j     : Soft Drop')
  table.insert(lines, 'Space   : Hard Drop')
  table.insert(lines, 'q Esc   : Quit')

  if state.game_over then
    table.insert(lines, '')
    table.insert(lines, 'GAME OVER!')
    table.insert(lines, string.format('Final Score: %d', state.score))
  end

  vim.bo[state.buf].modifiable = true
  vim.api.nvim_buf_set_lines(state.buf, 0, -1, false, lines)
  vim.bo[state.buf].modifiable = false

  state.ns_id = state.ns_id or api.nvim_create_namespace('tetris')
  api.nvim_buf_clear_namespace(state.buf, state.ns_id, 0, -1)

  for _, hl in ipairs(highlights) do
    vim.hl.range(
      state.buf,
      state.ns_id,
      hl.hl_group,
      { hl.line, hl.col_start },
      { hl.line, hl.col_end },
      {}
    )
  end
end

local function game_loop()
  if state.game_over then
    if state.timer and not state.timer:is_closing() then
      state.timer:stop()
      state.timer:close()
      state.timer = nil
    end
    render()
    return
  end

  if is_valid_position(state.current_piece, state.current_x, state.current_y + 1) then
    state.current_y = state.current_y + 1
  else
    lock_piece()
    clear_lines()
    spawn_piece()
  end

  render()
end

local function move(dx, dy)
  if state.game_over then
    return
  end

  local new_x = state.current_x + dx
  local new_y = state.current_y + dy

  if is_valid_position(state.current_piece, new_x, new_y) then
    state.current_x = new_x
    state.current_y = new_y
    render()
    return true
  end
  return false
end

local function rotate()
  if state.game_over then
    return
  end

  local piece = state.current_piece
  local piece_def = pieces[piece.name]
  local next_rotation = (piece.rotation % #piece_def.shapes) + 1

  local new_piece = {
    name = piece.name,
    shape = piece_def.shapes[next_rotation],
    color = piece.color,
    rotation = next_rotation,
    width = piece_def.width[next_rotation],
    height = piece_def.height[next_rotation],
  }

  if is_valid_position(new_piece, state.current_x, state.current_y) then
    state.current_piece = new_piece
    render()
    return
  end

  for _, offset in ipairs({ -1, 1, -2, 2 }) do
    if is_valid_position(new_piece, state.current_x + offset, state.current_y) then
      state.current_piece = new_piece
      state.current_x = state.current_x + offset
      render()
      return
    end
  end
end

local function hard_drop()
  if state.game_over then
    return
  end

  while move(0, 1) do
  end
end

local function setup_keymaps()
  local opts = { buffer = state.buf }
  vim.keymap.set('n', '<Left>', function()
    move(-1, 0)
  end, opts)
  vim.keymap.set('n', 'h', function()
    move(-1, 0)
  end, opts)
  vim.keymap.set('n', '<Right>', function()
    move(1, 0)
  end, opts)
  vim.keymap.set('n', 'l', function()
    move(1, 0)
  end, opts)
  vim.keymap.set('n', '<Down>', function()
    move(0, 1)
  end, opts)
  vim.keymap.set('n', 'j', function()
    move(0, 1)
  end, opts)
  vim.keymap.set('n', '<Up>', function()
    rotate()
  end, opts)
  vim.keymap.set('n', 'k', function()
    rotate()
  end, opts)
  vim.keymap.set('n', '<Space>', function()
    hard_drop()
  end, opts)
  vim.keymap.set('n', 'q', function()
    M.close()
  end, opts)
  vim.keymap.set('n', '<Esc>', function()
    M.close()
  end, opts)
end

function M.close()
  if state.timer and not state.timer:is_closing() then
    state.timer:stop()
    state.timer:close()
    state.timer = nil
  end

  if state.win and vim.api.nvim_win_is_valid(state.win) then
    vim.api.nvim_win_close(state.win, true)
  end

  state.win = nil
  state.buf = nil
end

function M.start()
  math.randomseed(os.time())
  setup_highlights()
  init_board()

  state.buf = api.nvim_create_buf(false, true)
  vim.bo[state.buf].bufhidden = 'wipe'
  vim.bo[state.buf].modifiable = false

  local width = config.width * config.block_size
  local height = config.height + 16

  local win_opts = {
    relative = 'editor',
    width = width,
    height = height,
    col = math.floor((vim.o.columns - width) / 2),
    row = math.floor((vim.o.lines - height) / 2),
    style = 'minimal',
    border = 'rounded',
    title = 'Tetris',
    title_pos = 'center',
  }

  state.win = vim.api.nvim_open_win(state.buf, true, win_opts)
  setup_keymaps()

  state.score = 0
  state.game_over = false
  state.speed = 500

  spawn_piece()
  render()

  state.timer = assert(uv.new_timer())
  state.timer:start(state.speed, state.speed, function()
    vim.schedule(function()
      game_loop()
    end)
  end)
end

api.nvim_create_user_command('Tetris', function()
  M.start()
end, {})

return M
