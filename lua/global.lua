local global = {}
local home    = os.getenv("HOME")
local path_sep = global.is_windows and '\\' or '/'

function global.load_variables()
  global.is_mac     = jit.os == 'OSX'
  global.is_linux   = jit.os == 'Linux'
  global.is_windows = jit.os == 'Windows'
  global.vim_path    = home .. path_sep..'.config'..path_sep..'nvim'
  global.cache_dir   = home .. path_sep..'.cache'..path_sep..'vim'..path_sep
  global.modules_dir = global.vim_path .. path_sep..'modules'
  global.path_sep = path_sep
  global.home = home
end


--- Check if a file or directory exists in this path
function global.exists(file)
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
function global.isdir(path)
  -- "/" works on both Unix and Windows
  return global.exists(path.."/")
end

function global.dump(o)
   if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. global.dump(v) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

function global.readAll(file)
    local f = assert(io.open(file, "rb"))
    local content = f:read("*all")
    f:close()
    return content
end

-- check value in table
function global.has_value (tab, val)
  for _, value in ipairs(tab) do
    if value == val then
      return true
    end
  end
  return false
end

-- check index in table
function global.has_key (tab,idx)
  for index,_ in pairs(tab) do
    if index == idx then
      return true
    end
  end
  return false
end

global.load_variables()

return global
