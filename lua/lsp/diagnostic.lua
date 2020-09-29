-- lsp dianostic
local global = require 'global'
local vim = vim
local api = vim.api
local lsp = vim.lsp
local window = require 'lsp.window'
local wrap = require 'lsp.wrap'
local M = {}

-- lsp severity icon
-- 1:Error 2:Warning 3:Information 4:Hint
local severity_icon = {
  "  Error",
  "  Warn",
  "  Infor",
  "  Hint"
}

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

-- TODO: when https://github.com/neovim/neovim/issues/12923 sovled
-- rewrite this function
function M.close_preview()
  local has_value,prev_win = pcall(api.nvim_buf_get_var,0,"diagnostic_float_window")
  if prev_win == nil then return end
  if has_value and prev_win[1] ~= nil and api.nvim_win_is_valid(prev_win[1]) then
    local current_position = vim.fn.getpos('.')
    local has_lineinfo,lines = pcall(api.nvim_buf_get_var,0,"diagnostic_prev_position")
    if has_lineinfo then
      if lines[1] ~= current_position[2] or lines[2] ~= current_position[3]-1 then
        api.nvim_win_close(prev_win[1],true)
        api.nvim_win_close(prev_win[2],true)
        api.nvim_buf_set_var(0,"diagnostic_float_window",nil)
        api.nvim_buf_set_var(0,"diagnostic_prev_position",nil)
        -- restore the hilight
        api.nvim_command("hi! link LspFloatWinBorder LspFloatWinBorder")
        api.nvim_command("hi! link DiagnosticTruncateLine DiagnosticTruncateLine")
      end
    end
  end
end

local function jump_to_entry(entry)
  local has_value,prev_fw = pcall(api.nvim_buf_get_var,0,"diagnostic_float_window")
  if has_value and prev_fw ~=nil and api.nvim_win_is_valid(prev_fw[1]) then
    api.nvim_win_close(prev_fw[1],true)
    api.nvim_win_close(prev_fw[2],true)
  end
  local diagnostic_message = {}
  local entry_line = get_line(entry) + 1
  local entry_character = get_character(entry)
  local hiname ={"DiagnosticError","DiagnosticWarning","DiagnosticInformation","DiagnosticHint"}
  table.insert(diagnostic_message,severity_icon[entry.severity])

  local wrap_message = wrap.wrap_line(entry.message,50)
  local truncate_line = wrap.add_truncate_line(wrap_message)
  table.insert(diagnostic_message,truncate_line)
  for _,v in pairs(wrap_message) do
    table.insert(diagnostic_message,v)
  end

  -- set curosr
  api.nvim_win_set_cursor(0, {entry_line, entry_character})
  local fb,fw,bw = window.create_float_window(diagnostic_message,'markdown',1,false,false)

  -- use a variable to control diagnostic floatwidnow
  api.nvim_buf_set_var(0,"diagnostic_float_window",{fw,bw})
  api.nvim_buf_set_var(0,"diagnostic_prev_position",{entry_line,entry_character})
  lsp.util.close_preview_autocmd({"CursorMovedI", "BufHidden", "BufLeave"}, fw)
  lsp.util.close_preview_autocmd({"CursorMovedI", "BufHidden", "BufLeave"}, bw)
  api.nvim_command("autocmd CursorMoved <buffer> lua require('lsp.diagnostic').close_preview()")

  --add highlight
  api.nvim_buf_add_highlight(fb,-1,hiname[entry.severity],0,0,-1)
  api.nvim_buf_add_highlight(fb,-1,"DiagnosticTruncateLine",1,0,-1)
  -- match current diagnostic syntax
  api.nvim_command("hi! link LspFloatWinBorder ".. hiname[entry.severity])
  api.nvim_command("hi! link DiagnosticTruncateLine "..hiname[entry.severity])
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

function M.quit_diagnostic_float_win()
  if M.contents_winid ~=nil and M.border_winid ~= nil and api.nvim_win_is_valid(M.border_winid) and api.nvim_win_is_valid(M.contents_winid) then
    api.nvim_win_close(M.contents_winid,true)
    api.nvim_win_close(M.border_winid,true)
  end
end

function M.jump_diagnostic_in_float(action_type)
  local action = {"vsplit","split"}
  local file_path = vim.fn.expand("%:p")
  local pos_info = vim.fn.split(vim.fn.getline(".")," ")
  local row,col = pos_info[#pos_info]:match("([^|]*)|?(.*)")
  M.quit_diagnostic_float_win()
  if action_type == 0 then
    api.nvim_win_set_cursor(0,{tonumber(row),tonumber(col)})
  else
    api.nvim_command(action[action_type]..file_path)
    api.nvim_win_set_cursor(0,{tonumber(row),tonumber(col)})
  end
end

local function apply_diagnostic_float_map()
  api.nvim_buf_set_keymap(M.contents_bufnr,"n","q","<Cmd>lua require'lsp.diagnostic'.quit_diagnostic_float_win()<CR>",{noremap = true,silent = true})
  api.nvim_buf_set_keymap(M.contents_bufnr,"n","<CR>","<cmd>lua require'lsp.diagnostic'.jump_diagnostic_in_float(0)<CR>",{noremap = true,silent= true})
  api.nvim_buf_set_keymap(M.contents_bufnr,"n","v","<cmd>lua require'lsp.diagnostic'.jump_diagnostic_in_float(1)<CR>",{noremap = true,silent= true})
  api.nvim_buf_set_keymap(M.contents_bufnr,"n","s","<cmd>lua require'lsp.diagnostic'.jump_diagnostic_in_float(2)<CR>",{noremap = true,silent= true})
end

function M.show_buf_diagnostics()
  local diagnostics = get_sorted_diagnostics()
  local buf_fname = vim.fn.expand("%:t")
  -- 1:Error 2:Warning 3:Information 4:Hint
  local buf_diagnostic_count = {0,0,0,0}
  local contents = {}
  local hi_name = {'DiagnosticFloatError','DiagnosticFloatWarn','DiagnositcFLoatInfo','DiagnosticFloatHint'}
  local syntax_line_map = {}
  for idx,diagnostic in ipairs(diagnostics) do
    buf_diagnostic_count[diagnostic.severity] = buf_diagnostic_count[diagnostic.severity] + 1
    local diagnostic_line = diagnostic.range.start.line + 1
    local diagnostic_character = diagnostic.range.start.character
    local split_message = vim.fn.split(diagnostic.message," ")
    local short_message = nil
    if #split_message > 4 then
      short_message = table.concat(split_message," ",1,4)
    end
    local content = severity_icon[diagnostic.severity] ..' '..diagnostic_line..'|'..diagnostic_character..' '..
    '['..short_message..']'
    table.insert(contents,content)
    syntax_line_map[1+idx] = hi_name[diagnostic.severity]
  end
  local title = '🐞 File: '..buf_fname
  local diagnostic_map = {"Error:","Warn:","Info:","Hint:"}
  for idx,v in ipairs(buf_diagnostic_count) do
    if v ~= 0 then
      title = title..' '..diagnostic_map[idx]..v
    end
  end
  local truncate_line = wrap.add_truncate_line(contents)
  local buf_diagnostic_contents = {title,truncate_line}
  for _,content in pairs(contents) do
    table.insert(buf_diagnostic_contents,content)
  end

  -- get dimensions
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  -- calculate our floating window size
  local win_height = math.ceil(height * 0.8 - 4)
  local win_width = math.ceil(width * 0.8)

  -- and its starting position
  local row = math.ceil((height - win_height))
  local col = math.ceil((width - win_width)-1)

  -- set some options
  local opts = {
    style = "minimal",
    relative = "editor",
    row = row,
    col = col,
  }

  M.contents_bufnr,M.contents_winid,M.border_winid = window.create_float_window(buf_diagnostic_contents,'plaintext',1,true,false,opts)
  if #buf_diagnostic_contents > 2 then
    api.nvim_win_set_cursor(0,{3,5})
  end
  apply_diagnostic_float_map()
  -- add highlight
  api.nvim_buf_add_highlight(M.contents_bufnr,-1,"DiagnosticBufferTitle",0,0,-1)
  for line,hi in pairs(syntax_line_map) do
    api.nvim_buf_add_highlight(M.contents_bufnr,-1,hi,line,0,-1)
  end
end

return M
