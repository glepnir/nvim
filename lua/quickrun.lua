local global = require 'global'
local vim = vim
local M = {}

do
  M.go = {'go run ','go test '}
  M.lua = {'lua '}
end

function M.run_command()
  local cmd = nil
  local file_extension = vim.fn.expand("%:e")
  local file_name = vim.fn.expand("%:p")
  if file_extension == 'go' then
    if file_name:match("_test") then
      cmd = M[file_extension][2]
    else
      cmd = M[file_extension][1]
    end
  else
    cmd = M[file_extension][1]
  end
  local output_list = vim.fn.split(vim.fn.system(cmd..file_name),'\n')
  for _,v in ipairs(output_list) do
    print(v)
  end
end

return M
