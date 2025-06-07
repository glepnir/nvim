local api = vim.api

-- Class for managing bracket pairs
local BracketPair = {}
BracketPair.__index = BracketPair

function BracketPair.new()
  local self = setmetatable({}, BracketPair)
  self.pairs = {
    ['('] = ')',
    ['['] = ']',
    ['{'] = '}',
    ['"'] = '"',
    ["'"] = "'",
    ['`'] = '`',
  }
  -- Extend with any user-defined pairs
  self.pairs = vim.tbl_extend('keep', self.pairs, vim.g.fnpairs or {})
  return self
end

function BracketPair:get_closing(opening)
  return self.pairs[opening]
end

function BracketPair:is_opening(char)
  return self.pairs[char] ~= nil
end

function BracketPair:is_balanced(str, opening_char)
  local stack = {}
  for i = 1, #str do
    local c = str:sub(i, i)
    if self.pairs[c] then
      table.insert(stack, c)
    elseif c == self.pairs[opening_char] then
      if #stack == 0 or stack[#stack] ~= opening_char then
        return false
      end
      table.remove(stack)
    end
  end
  return true
end

-- Class for managing editor state
local State = {}
State.__index = State

function State.new()
  local self = setmetatable({}, State)
  self.line = api.nvim_get_current_line()
  self.cursor = api.nvim_win_get_cursor(0)
  self.mode = api.nvim_get_mode().mode
  return self
end

function State:get_word_before()
  local col = self.cursor[2]
  if col == 0 then
    return ''
  end

  local start_pos = col
  while start_pos > 0 do
    local char = self.line:sub(start_pos, start_pos)
    if char:match('%s') then
      start_pos = start_pos + 1
      break
    end
    start_pos = start_pos - 1
  end

  if start_pos == 0 then
    start_pos = 1
  end

  return self.line:sub(start_pos, col)
end

function State:get_char_before()
  local pos = self.cursor[2]
  if pos > 0 then
    return self.line:sub(pos, pos)
  end
  return nil
end

function State:get_char_after()
  local pos = self.cursor[2] + 1
  if pos <= #self.line then
    return self.line:sub(pos, pos)
  end
  return nil
end

-- Action classes
local ActionType = {
  SKIP = 'skip',
  INSERT = 'insert',
  DELETE = 'delete',
  NOTHING = 'nothing',
}

local Action = {}
Action.__index = Action

function Action.skip()
  return setmetatable({
    type = ActionType.SKIP,
  }, Action)
end

function Action.insert(opening, closing)
  return setmetatable({
    type = ActionType.INSERT,
    opening = opening,
    closing = closing,
  }, Action)
end

function Action.delete()
  return setmetatable({
    type = ActionType.DELETE,
  }, Action)
end

function Action.nothing(char)
  return setmetatable({
    type = ActionType.NOTHING,
    char = char,
  }, Action)
end

-- Action handler
local ActionHandler = {}

function ActionHandler.handle(action, state, bracket_pairs)
  if action.type == ActionType.SKIP then
    return '<Right>'
  elseif action.type == ActionType.INSERT then
    return action.opening .. action.closing .. '<Left>'
  elseif action.type == ActionType.DELETE then
    local before = state:get_char_before()
    local after = state:get_char_after()
    if before and after and bracket_pairs:get_closing(before) == after then
      return '<BS><Del>'
    end
    return '<BS>'
  else -- NOTHING insert char self
    return action.char or ''
  end
end

-- Main plugin class
local Pairs = {}
Pairs.__index = Pairs

function Pairs.new()
  local self = setmetatable({}, Pairs)
  self.bracket_pairs = BracketPair.new()
  return self
end

function Pairs:determine_action(char, state)
  -- Handle visual mode
  if state.mode == 'v' or state.mode == 'V' then
    return Action.insert(char, self.bracket_pairs:get_closing(char))
  end

  -- Check ' used in binary number
  if char == "'" then
    local word_before = state:get_word_before()
    if word_before and word_before:match('0b[01]*$') then
      return Action.nothing(char)
    end
  end

  -- Check if we should skip closing bracket
  local next_char = state:get_char_after()
  if next_char and next_char == self.bracket_pairs:get_closing(char) then
    -- Check bracket balance
    local substr = state.line:sub(state.cursor[2] + 1)
    if self.bracket_pairs:is_balanced(substr, char) then
      return Action.skip()
    end
  end

  return Action.insert(char, self.bracket_pairs:get_closing(char))
end

function Pairs:handle_char(char)
  local state = State.new()
  local action = self:determine_action(char, state)
  return ActionHandler.handle(action, state, self.bracket_pairs)
end

function Pairs:handle_backspace()
  local state = State.new()
  return ActionHandler.handle(Action.delete(), state, self.bracket_pairs)
end

function Pairs:setup()
  -- Store reference to self to avoid closure issues
  local plugin = self

  -- Setup bracket pairs
  for opening, _ in pairs(self.bracket_pairs.pairs) do
    vim.keymap.set('i', opening, function()
      return plugin:handle_char(opening)
    end, { expr = true })
  end

  -- Setup backspace handling
  vim.keymap.set('i', '<BS>', function()
    return plugin:handle_backspace()
  end, { expr = true })
end

Pairs.new():setup()
