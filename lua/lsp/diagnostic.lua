-- lsp dianostic
local global = require('global')
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

local function open_floating_preview(contents, filetype, opts)
  opts = opts or {}

  -- Clean up input: trim empty lines from the end, pad
  contents = vim.lsp.util._trim_and_pad(contents, opts)

  -- Compute size of float needed to show (wrapped) lines
  opts.wrap_at = opts.wrap_at or (vim.wo["wrap"] and api.nvim_win_get_width(0))
  local width, height = vim.lsp.util._make_floating_popup_size(contents, opts)

  local floating_bufnr = api.nvim_create_buf(false, true)
  if filetype then
    api.nvim_buf_set_option(floating_bufnr, 'filetype', filetype)
  end
  local float_option = vim.lsp.util.make_floating_popup_options(width, height, opts)
  local floating_winnr = api.nvim_open_win(floating_bufnr, false, float_option)
  if filetype == 'markdown' then
    api.nvim_win_set_option(floating_winnr, 'conceallevel', 2)
  end
  api.nvim_buf_set_lines(floating_bufnr, 0, -1, true, contents)
  api.nvim_buf_set_option(floating_bufnr, 'modifiable', false)
  return floating_bufnr, floating_winnr
end

function M.close_preview()
  local has_value,fw = pcall(api.nvim_buf_get_var,0,"diagnostic_float_window")
  if has_value and fw ~= nil and api.nvim_win_is_valid(fw) then
    local current_position = vim.fn.getpos('.')
    local has_lineinfo,lines = pcall(api.nvim_buf_get_var,0,"diagnostic_prev_position")
    if has_lineinfo then
      if lines[1] ~= current_position[2] or lines[2] ~= current_position[3]-1 then
        api.nvim_win_close(fw,true)
        api.nvim_buf_set_var(0,"diagnostic_float_window",nil)
        api.nvim_buf_set_var(0,"diagnostic_prev_position",nil)
      end
    end
  end
end

local function jump_to_entry(entry)
  local has_value,prev_fw = pcall(api.nvim_buf_get_var,0,"diagnostic_float_window")
  if has_value and prev_fw ~=nil then
    api.nvim_win_close(prev_fw,true)
  end
  local diagnostic_message = {}
  local entry_line = get_line(entry) + 1
  local entry_character = get_character(entry)
  -- lsp severity icon
  -- 1:Error 2:Warning 3:Information 4:Hint
  local severity_icon = {"   Error","   Warning","   Information:","   Hint"}
  local hiname ={"DiagnosticError","DiagnosticWarning","DiagnosticInformation","DiagnosticHint"}
  table.insert(diagnostic_message,severity_icon[entry.severity])
  local truncate_line = '─'
  for _=1,#entry.message+1,1 do
      truncate_line = truncate_line .. '─'
  end
  table.insert(diagnostic_message,truncate_line)
  table.insert(diagnostic_message,entry.message)
  api.nvim_win_set_cursor(0, {entry_line, entry_character})
  local fb,fw = open_floating_preview(diagnostic_message,'markdown',{pad_left=0,pad_right=0})
  api.nvim_buf_set_var(0,"diagnostic_float_window",fw)
  api.nvim_buf_set_var(0,"diagnostic_prev_position",{entry_line,entry_character})
  lsp.util.close_preview_autocmd({"CursorMovedI", "BufHidden", "BufLeave"}, fw)
  api.nvim_command("autocmd CursorMoved <buffer> lua require('lsp.diagnostic').close_preview()")

  --add highlight
  api.nvim_buf_add_highlight(fb,-1,hiname[entry.severity],0,0,-1)
  api.nvim_buf_add_highlight(fb,-1,"DiagnosticTruncateLine",1,0,-1)
  api.nvim_command("hi DiagnosticTruncateLine guifg=black gui=bold")
  api.nvim_command("hi DiagnosticError guifg=#EC5f67 gui=bold")
  api.nvim_command("hi DiagnosticWarning guifg=#d8a657 gui=bold")
  api.nvim_command("hi DiagnosticInformation guifg=#6699cc gui=bold")
  api.nvim_command("hi DiagnosticHint guifg=#56b6c2 gui=bold")
end


local function jump_one_times(get_entry_function)
  for _ = 1, 1, -1 do
      local entry = get_entry_function()

      if entry == nil then
          break
      else
          jump_to_entry(entry)
      end
  end
end

function M.lsp_jump_diagnostic_prev()
  jump_one_times(get_above_entry)
end

function M.lsp_jump_diagnostic_next()
  jump_one_times(get_below_entry)
end

return M
