is_mac     = jit.os == 'OSX'
is_linux   = jit.os == 'Linux'
is_windows = jit.os == 'Windows'

home        = os.getenv("HOME")
vim_path    = home .. '/.config/nvim'
cache_dir   = home .. '/.cache/vim/'
map_dir     = vim_path .. 'maps/'
modules_dir = vim_path .. '/modules'

--- Check if a file or directory exists in this path
function exists(file)
  local ok, err, code = os.rename(file, file)
  if not ok then
    if code == 13 then
      -- Permission denied, but it exists
      return true
    end
  end
  return ok, err
end

--- Check if a directory exists in this path
function isdir(path)
  -- "/" works on both Unix and Windows
  return exists(path.."/")
end

function dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end


function map_not_recursive(cmd_string)
  return {cmd_string,{noremap = true}}
end

function map_recursive(cmd_string)
  return {cmd_string,{noremap = false}}
end

function map_recursive_silent(cmd_string)
  return {cmd_string,{noremap = false,silent = true}}
end

function map_not_recursive_silent(cmd_string)
  return {(":%s<CR>"):format(cmd_string),{noremap = true,silent =true}}
end

function map_not_recursive_cr(cmd_string)
  return {(":%s<CR>"):format(cmd_string),{noremap = true}}
end

function map_not_recursive_silentcr(cmd_string)
  return {(":%s<CR>"):format(cmd_string),{noremap = true,silent = true}}
end

function map_recursive_silentcr(cmd_string)
  return {(":%s<CR>"):format(cmd_string),{noremap = false,silent = true}}
end

function map_recursive_cr(cmd_string)
  return {(":%s<CR>"):format(cmd_string),{noremap = false}}
end

function map_not_recursive_cu(cmd_string)
  return {(":<C-u>%s<CR>"):format(cmd_string),{noremap = true}}
end

function map_not_recursive_silentcu(cmd_string)
  return {(":<C-u>%s<CR>"):format(cmd_string),{noremap = true,silent= true}}
end

function map_recursive_silentcu(cmd_string)
  return {(":<C-u>%s<CR>"):format(cmd_string),{noremap = false,silent= true}}
end

function map_not_recursive_expr(cmd_string)
  return {cmd_string,{noremap = true,expr = true}}
end

function map_recursive_expr(cmd_string)
  return {cmd_string,{noremap = false,expr = true}}
end
