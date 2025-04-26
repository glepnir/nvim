local api = vim.api
local M = {}

local state = {
  active = false,
  mode = nil,
  ns_id = nil,
  key_map = {},
  on_key_func = nil,
  pending_key = nil,
  keyseq_length = 1,
}

local function cleanup()
  if state.active then
    if state.ns_id then
      vim.api.nvim_buf_clear_namespace(0, state.ns_id, 0, -1)
    end

    if state.on_key_func then
      vim.on_key(nil, state.ns_id)
      state.on_key_func = nil
    end

    state.active = false
    state.mode = nil
    state.key_map = {}
    state.pending_key = nil
  end
end

local function generate_keys(count)
  local keys = 'asdghklqwertyuiopzxcvbnmfjASDGHLQWERTYUIOPZXCVBNMFJ'
  local key_len = #keys
  local result = {}

  if count <= key_len then
    for i = 1, count do
      table.insert(result, string.sub(keys, i, i))
    end
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
  state.pending_key = nil

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

  state.on_key_func = function(char)
    if not state.active then
      return
    end

    if char == '\27' then
      cleanup()
      return
    end

    local target = state.key_map[char]
    if target then
      api.nvim_win_set_cursor(0, { target.row + 1, target.col })
      cleanup()
      return ''
    end
    cleanup()
  end

  vim.on_key(state.on_key_func, state.ns_id)
end

-- char jump
function M.char(char_to_find)
  if state.active then
    cleanup()
  end

  local char_input = char_to_find

  if not char_input then
    local ok, char = pcall(function()
      return vim.fn.nr2char(vim.fn.getchar())
    end)
    if not ok or not char or char == '' or char == vim.fn.nr2char(27) then
      return false
    end
    char_input = char
  end

  state.active = true
  state.mode = 'char'

  local first_line = vim.fn.line('w0') - 1
  local last_line = vim.fn.line('w$')

  local lines = api.nvim_buf_get_lines(0, first_line, last_line, false)
  local targets = {}

  for i, line in ipairs(lines) do
    local row = first_line + i - 1
    local pos = 0

    while true do
      pos = string.find(line, char_input, pos + 1, true)
      if not pos then
        break
      end

      table.insert(targets, { row = row, col = pos - 1 })
    end
  end

  if #targets == 0 then
    return
  end

  mark_targets(targets)
end

api.nvim_set_hl(0, 'JumpMotionTarget', {
  fg = '#ff0000',
  bold = true,
})

api.nvim_create_autocmd({ 'CursorMoved', 'InsertEnter', 'BufLeave', 'WinLeave' }, {
  callback = function()
    if state.active then
      cleanup()
    end
  end,
})

return { char = M.char }
