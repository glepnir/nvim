-- Minimal asynchronous fast jump based on rg

local api = vim.api
local M = {}
local FORWARD, BACKWARD = 1, -1

local state = {
  active = false,
  mode = nil,
  ns_id = nil,
  key_map = {},
  on_key_func = nil,
  max_targets = 60, -- keys count
}

local function cleanup()
  if state.active then
    if state.ns_id then
      api.nvim_buf_clear_namespace(0, state.ns_id, 0, -1)
    end
    if state.on_key_func then
      vim.on_key(nil, state.ns_id)
      state.on_key_func = nil
    end

    state.active = false
    state.mode = nil
    state.key_map = {}

    if state.id then
      api.nvim_del_autocmd(state.id)
    end
  end
end

local function generate_keys(count)
  local keys = 'asdghjklzxcvbnmqwertyuiopASDGHJLZXCVBNMQWERTYUIOP1234567890'
  local key_len = #keys
  local result = {}

  for i = 1, math.min(count, key_len) do
    table.insert(result, string.sub(keys, i, i))
  end

  return result
end

local function mark_targets(targets)
  if not state.ns_id then
    state.ns_id = api.nvim_create_namespace('jumpmotion')
  end

  api.nvim_buf_clear_namespace(0, state.ns_id, 0, -1)

  local keys = generate_keys(#targets)
  state.key_map = {}

  for i, target in ipairs(targets) do
    if i <= #keys then
      local key = keys[i]
      state.key_map[key] = target

      api.nvim_buf_set_extmark(0, state.ns_id, target.row, target.col, {
        virt_text = { { key, 'JumpMotionTarget' } },
        virt_text_pos = 'overlay',
        priority = 100,
      })
    end
  end

  state.on_key_func = function(char, typed)
    if not state.active then
      return
    end

    if char == '\27' then
      cleanup()
      return
    end

    local target = state.key_map[typed]
    if target then
      api.nvim_win_set_cursor(0, { target.row + 1, target.col })
      cleanup()
      return ''
    end
  end

  vim.on_key(state.on_key_func, state.ns_id)

  state.id = api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave', 'WinLeave' }, {
    once = true,
    callback = function()
      if state.active then
        cleanup()
      end
    end,
  })
end

function M.char(direction)
  if vim.fn.executable('rg') == 0 or vim.fn.line2byte(vim.fn.line('$') + 1) == -1 then
    return
  end

  return function()
    async(function()
      if state.active then
        cleanup()
      end

      local ok, char = pcall(function()
        return vim.fn.nr2char(vim.fn.getchar())
      end)
      if not ok or not char or char == '' or char == vim.fn.nr2char(27) then
        return false
      end
      local char_input = char

      state.active = true
      state.mode = 'char'

      local first_line = vim.fn.line('w0') - 1
      local curow = api.nvim_win_get_cursor(0)[1] - 1
      if curow == 0 and direction == BACKWARD then
        return
      end
      local last_line = vim.fn.line('w$')

      local lines
      local base_row

      if direction == FORWARD then
        base_row = curow + 1
        lines = api.nvim_buf_get_lines(0, curow + 1, last_line, false)
      else
        base_row = first_line
        lines = api.nvim_buf_get_lines(0, first_line, curow, false)
        local reversed_lines = {}
        for i = #lines, 1, -1 do
          table.insert(reversed_lines, lines[i])
        end
        lines = reversed_lines
      end

      local visible_text = table.concat(lines, '\n')

      local cmd = {
        'rg',
        '--json',
        '--fixed-strings',
        char_input,
      }

      local result = await(asystem(cmd, { stdin = visible_text }))

      local targets = {}
      local count = 0

      if result.stdout then
        for line in string.gmatch(result.stdout, '[^\r\n]+') do
          if line:find('"type":"match"') then
            local ok, json = pcall(vim.json.decode, line)
            if ok and json and json.type == 'match' and json.data then
              local row = json.data.line_number - 1

              if json.data.submatches and #json.data.submatches > 0 then
                for _, submatch in ipairs(json.data.submatches) do
                  local col = submatch.start

                  local actual_row
                  if direction == FORWARD then
                    actual_row = base_row + row
                  else
                    actual_row = curow - 1 - row
                  end

                  table.insert(targets, {
                    row = actual_row,
                    col = col,
                  })

                  count = count + 1
                  if count >= state.max_targets then
                    break
                  end
                end
              end

              if count >= state.max_targets then
                break
              end
            end
          end
        end
      end

      if direction == BACKWARD then
        table.sort(targets, function(a, b)
          return a.row < b.row
        end)
      end

      if #targets == 0 then
        cleanup()
        return
      end

      mark_targets(targets)
    end)()
  end
end

api.nvim_set_hl(0, 'JumpMotionTarget', {
  fg = '#ff4800',
  bold = true,
})

return { charForward = M.char(FORWARD), charBackward = M.char(BACKWARD) }
