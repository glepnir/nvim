is_mac     = jit.os == 'OSX'
is_linux   = jit.os == 'Linux'
is_windows = jit.os == 'Windows'

path_sep = is_windows and '\\' or '/'

home        = os.getenv("HOME")
vim_path    = home .. path_sep..'.config'..path_sep..'nvim'
cache_dir   = home .. path_sep..'.cache'..path_sep..'vim'..path_sep
map_dir     = vim_path .. 'maps'..path_sep
modules_dir = vim_path .. path_sep..'modules'


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
