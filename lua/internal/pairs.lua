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
  return self
end

function BracketPair:get_closing(opening)
  return self.pairs[opening]
end

function BracketPair:is_opening(char)
  return self.pairs[char] ~= nil
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

-- Action classes using composition instead of inheritance
local ActionType = {
  SKIP = 'skip',
  INSERT = 'insert',
  DELETE = 'delete',
  NOTHING = 'nothing',
}

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
  else -- NOTHING
    return ''
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
    return {
      type = ActionType.INSERT,
      opening = char,
      closing = self.bracket_pairs:get_closing(char),
    }
  end

  -- Check if we should skip closing bracket
  local next_char = state:get_char_after()
  if next_char and next_char == self.bracket_pairs:get_closing(char) then
    return { type = ActionType.SKIP }
  end

  -- Handle apostrophe in code (don't pair if preceded by word character)
  local prev_char = state:get_char_before()
  if char == "'" and prev_char and string.match(prev_char, '[%w]') then
    return {
      type = ActionType.INSERT,
      opening = char,
      closing = '',
    }
  end

  -- Default: insert pair
  return {
    type = ActionType.INSERT,
    opening = char,
    closing = self.bracket_pairs:get_closing(char),
  }
end

function Pairs:handle_char(char)
  local state = State.new()
  local action = self:determine_action(char, state)
  return ActionHandler.handle(action, state, self.bracket_pairs)
end

function Pairs:handle_backspace()
  local state = State.new()
  local action = { type = ActionType.DELETE }
  return ActionHandler.handle(action, state, self.bracket_pairs)
end

function Pairs:setup()
  -- Store reference to self to avoid closure issues
  local plugin = self

  -- Setup bracket pairs
  for opening, _ in pairs(plugin.bracket_pairs.pairs) do
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
