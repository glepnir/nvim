-- lsp dianostic
local vim = vim
local api = vim.api
local lsp = vim.lsp
local M = {}

local function get_line(diagnostic_entry)
  return diagnostic_entry["range"]["start"]["line"]
end

local function get_character(diagnostic_entry)
  return diagnostic_entry["range"]["start"]["character"]
end

local function compare_positions(line_a, line_b, character_a, character_b)
  if line_a < line_b then
      return true
  elseif line_b < line_a then
      return false
  elseif character_a < character_b then
      return true
  else
      return false
  end
end

local function compare_diagnostics_entries(entry_a, entry_b)
  local line_a = get_line(entry_a)
  local line_b = get_line(entry_b)
  local character_a = get_character(entry_a)
  local character_b = get_character(entry_b)
  return compare_positions(line_a, line_b, character_a, character_b)
end

local function get_sorted_diagnostics()
  local buffer_number = api.nvim_get_current_buf()
  local diagnostics = lsp.util.diagnostics_by_buf[buffer_number]

  if diagnostics ~= nil then
      table.sort(diagnostics, compare_diagnostics_entries)
      return diagnostics
  else
      return {}
  end
end

local function get_above_entry()
  local diagnostics = get_sorted_diagnostics()
  local cursor = api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1]
  local cursor_character = cursor[2] - 1

  for i = #diagnostics, 1, -1 do
      local entry = diagnostics[i]
      local entry_line = get_line(entry)
      local entry_character = get_character(entry)

      if not compare_positions(cursor_line - 1, entry_line, cursor_character - 1, entry_character) then
          return entry
      end
  end

  return nil
end

local function get_below_entry()
  local diagnostics = get_sorted_diagnostics()
  local cursor = api.nvim_win_get_cursor(0)
  local cursor_line = cursor[1] - 1
  local cursor_character = cursor[2]

  for _, entry in ipairs(diagnostics) do
      local entry_line = get_line(entry)
      local entry_character = get_character(entry)

      if compare_positions(cursor_line, entry_line, cursor_character, entry_character) then
          return entry
      end
  end

  return nil
end

local function jump_to_entry(entry)
  local entry_line = get_line(entry) + 1
  local entry_character = get_character(entry)
  api.nvim_win_set_cursor(0, {entry_line, entry_character})
end

local function jump_n_times(count, get_entry_function)
  for _ = count, 1, -1 do
      local entry = get_entry_function()

      if entry == nil then
          print("No diagnostic entry to jump further!")
          break
      else
          jump_to_entry(entry)
      end
  end
end

function M.lsp_jump_diagnostic_prev(count)
  jump_n_times(count, get_above_entry)
end

function M.lsp_jump_diagnostic_next(count)
  jump_n_times(count, get_below_entry)
end

return M
