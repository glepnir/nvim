local vim,api = vim,vim.api
local window = require('lspsaga.window')
local M = {
  go = {'go run ','go test '};
  lua = {'lua '}
}

function M.enable_fold()
  if vim.o.runtimepath:find('nvim-treesitter') then
    vim.api.nvim_command('set foldmethod=expr')
    vim.api.nvim_command('set foldexpr=nvim_treesitter#foldexpr()')
  end
end

function M.run_command()
  local cmd = nil
  local file_type = vim.fn.expand("%:e")
  local file_name = vim.fn.expand("%:p")
  if vim.bo.file_type == 'dashboard' then return end
  if vim.bo.file_type == 'LuaTree' then return end
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

  local contents_bufnr,contents_winid,_,shadow_winid = window.open_shadow_float_win({},'Floaterm',true,false,opts)
  api.nvim_command('hi Floaterm guibg=#282c34')
  api.nvim_command('terminal '..cmd)
  api.nvim_command('setlocal nobuflisted')
  api.nvim_command('startinsert!')
  api.nvim_buf_set_var(contents_bufnr,'float_terminal_win',{contents_winid,shadow_winid})
end

function M.close_float_terminal()
  local float_terminal_win = api.nvim_buf_get_var(0,'float_terminal_win')
  if float_terminal_win[1] ~= nil and api.nvim_win_is_valid(float_terminal_win[1]) and float_terminal_win[2] ~= nil and api.nvim_win_is_valid(float_terminal_win[2]) then
    api.nvim_win_close(float_terminal_win[1],true)
    api.nvim_win_close(float_terminal_win[2],true)
  end
end

function M.blameVirtualText()
  local fname = vim.fn.expand('%')
  if not vim.fn.filereadable(fname) then return end
  if vim.fn.system('git rev-parse --show-toplevel'):find("fatal") then return end

  local ns_id = api.nvim_create_namespace("GitLens")
  api.nvim_buf_clear_namespace(0, ns_id, 0, -1)

  local line = api.nvim_win_get_cursor(0)
  local blame = vim.fn.system(string.format("git blame -c -L %d,%d %s", line[1], line[1], fname))
  if vim.v.shell_error > 0 then return end
  local hash = vim.split(blame, '%s')[1]
  if hash == '00000000' then return end

  local cmd = string.format("git show %s ", hash) .. "--format=' : %an | %ar | %s'"
  local text = vim.fn.system(cmd)
  text = vim.split(text, "\n")[1]
  if text:find("fatal") then return end

  api.nvim_buf_set_virtual_text(0, ns_id, line[1]-1, {{ text, "GitLens" }}, {})
  api.nvim_command("highlight! link GitLens Comment")
end

function M.clearBlameVirtualText()
  local ns_id = api.nvim_create_namespace("GitLens")
  api.nvim_buf_clear_namespace(0, ns_id, 0, -1)
end

return M
