local vim, api = vim, vim.api
local M = {
  go = { 'go run ', 'go test ' },
  lua = { 'lua ' },
}

function M.run_command()
  local cmd = nil
  local file_type = vim.fn.expand('%:e')
  local file_name = vim.fn.expand('%:p')
  if vim.bo.filetype == 'dashboard' then
    return
  end
  if vim.bo.filetype == 'LuaTree' then
    return
  end
  if file_type == 'go' then
    if file_name:match('_test') then
      cmd = M[file_type][2]
    else
      cmd = M[file_type][1]
    end
  else
    cmd = M[file_type][1]
  end
  local output_list = vim.fn.split(vim.fn.system(cmd .. file_name), '\n')
  for _, v in ipairs(output_list) do
    print(v)
  end
end
