local helper = {}
local home = os.getenv('HOME')
-- local is_windows = package.config:sub(1,1) == '\\'

function helper.get_config_path()
  local config = os.getenv('XDG_CONFIG_DIR')
  if not config then
    return home .. '/.config/nvim'
  end
  return config
end

function helper.get_data_path()
  local data = os.getenv('XDG_DATA_DIR')
  if not data then
    return home .. '/.local/share/nvim'
  end
  return data
end

local colors = {
  red = '\027[31m',
  green = '\027[32m',
  orange = '\027[33m',
  navy = '\027[34m',
  magenta = '\027[35m',
  cyan = '\027[36m',
  grey = '\027[90m',
  light_grey = '\027[37m',
  peach = '\027[91m',
  light_green = '\027[92m',
  yellow = '\027[93m',
  blue = '\027[94m',
  pink = '\027[95m',
  baby_blue = '\027[96m',
}

local function color_print(color)
  return function(text)
    print(colors[color] .. text .. '\027[m')
  end
end

function helper.install_success(msg)
  color_print('green')('\t🍻 Install ' .. msg .. ' Success ‼️ ')
end

function helper.error(msg)
  color_print('red')(msg)
end

function helper.test_internet()
  helper.cyan('Waiting for internet test ...')
  local handle = io.popen('ping github.com -c 4')
  while true do
    local output = handle:read('*l')
    if output == nil then
      break
    end
    if output:find('Reqeust timeout') then
      helper.error('Ping github failed check your internet')
      os.exit()
    end
  end
  handle:close()
end

local git_type = {
  clone = 'git clone https://github.com/',
  pull = 'git -C ',
}

local function git_cmd(param, type)
  if type == 'clone' then
    return git_type[type] .. param
  end
  return git_type[type] .. param .. ' pull'
end

function helper.run_git(param, type)
  local cmd = git_cmd(param, type)
  local handle = io.popen(cmd .. ' 2>&1')
  local name_path = vim.split(param, '%s')
  while true do
    local output = handle:read('*l')
    if not output then
      break
    end
    output = string.gsub(string.gsub(string.gsub(output, '^%s+', ''), '%s+$', ''), '[\n\r]+', ' ')
    if output:find('fatal') then
      helper.navy(output)
      helper.error('\t ⛔️ download or update ' .. name_path[1] .. ' failed')
      helper.pink('Rollback')
      if type == 'clone' then
        require('core.cli').clean()
      end
      os.exit()
    end
  end
  handle:close()
end

local function exists(file)
  local ok, _, code = os.rename(file, file)
  if not ok then
    if code == 13 then
      return true
    end
  end
  return ok
end

--- Check if a directory exists in this path
function helper.isdir(path)
  return exists(path .. '/')
end

setmetatable(helper, {
  __index = function(_, k)
    return color_print(k)
  end,
})

return helper
