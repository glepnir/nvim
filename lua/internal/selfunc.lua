local vim,api = vim,vim.api
local M = {
  go = {'go run ','go test '};
  lua = {'lua '}
}

function M.run_command()
  local cmd = nil
  local file_type = vim.fn.expand("%:e")
  local file_name = vim.fn.expand("%:p")
  if vim.bo.filetype == 'dashboard' then return end
  if vim.bo.filetype == 'LuaTree' then return end
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
