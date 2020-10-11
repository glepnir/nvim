local global = require('global')
local vim,api = vim,vim.api
local window = require('lsp.window')
local M = {
  go = {'go run ','go test '};
  lua = {'lua '}
}

function M.run_command()
  local cmd = nil
  local file_type = vim.fn.expand("%:e")
  local file_name = vim.fn.expand("%:p")
  if file_type == 'go' then
    if file_name:match("_test") then
      cmd = M[file_type][2]
    else
      cmd = M[file_type][1]
    end
  else
    cmd = M[file_type][1]
  end
  local output_list = vim.fn.split(vim.fn.system(cmd..file_name),'\n')
  for _,v in ipairs(output_list) do
    print(v)
  end
end

local function load_env_file()
  local env_file = os.getenv("HOME")..'/.env'
  local env_contents = {}
  if vim.fn.filereadable(env_file) ~= 1 then
    print('.env file does not exist')
    return
  end
  local contents = vim.fn.readfile(env_file)
  for _,item in pairs(contents) do
    local line_content = vim.fn.split(item,"=")
    env_contents[line_content[1]] = line_content[2]
  end
  return env_contents
end

function M.load_dbs()
  local env_contents = load_env_file()
  local dbs = {}
  for key,value in pairs(env_contents) do
    if vim.fn.stridx(key,"DB_CONNECTION_") >= 0 then
      local db_name = vim.fn.split(key,"_")[3]:lower()
      dbs[db_name] = value
    end
  end
  return dbs
end

function M.float_terminal(command)
  local cmd = command or ''

  -- get dimensions
  local width = api.nvim_get_option("columns")
  local height = api.nvim_get_option("lines")

  -- calculate our floating window size
  local win_height = math.ceil(height * 0.8)
  local win_width = math.ceil(width * 0.8)

  -- and its starting position
  local row = math.ceil((height - win_height) * 0.4)
  local col = math.ceil((width - win_width) * 0.5)

  -- set some options
  local opts = {
    style = "minimal",
    relative = "editor",
    width = win_width,
    height = win_height,
    row = row,
    col = col,
  }

  local contents_bufnr,contents_winid,border_winid = window.create_float_window({},'floaterm',1,true,false,opts)
  api.nvim_command('terminal '..cmd)
  api.nvim_command('startinsert!')
  api.nvim_command("hi LspFloatWinBorder guifg=#c594c5")
  api.nvim_buf_set_var(contents_bufnr,'float_terminal_win',{contents_winid,border_winid})
end

function M.close_float_terminal()
  local float_terminal_win = api.nvim_buf_get_var(0,'float_terminal_win')
  if float_terminal_win[1] ~= nil and api.nvim_win_is_valid(float_terminal_win[1]) and float_terminal_win[2] ~= nil and api.nvim_win_is_valid(float_terminal_win[2]) then
    api.nvim_win_close(float_terminal_win[1],true)
    api.nvim_win_close(float_terminal_win[2],true)
  end
end

return M
