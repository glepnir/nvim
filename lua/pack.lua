local pack = {}
local global = require('global')
local data_dir = string.format('%s/site/',vim.fn.stdpath('data'))
local plugins_cache = data_dir .. 'plugin/plugins_cache.txt'
local packer_compiled = data_dir..'plugin/packer_compiled.vim'
local newConsumer

function pack:new()
  local instance = {}
  setmetatable(instance,self)
  self.__index = self
  self.repos = {}
  self.modules = {}
  return instance
end

function pack:parse_config()
  local modules_dir = global.vim_path .. '/lua/modules'
  local p = io.popen('find "'..modules_dir..'" -name "*.lua"')
  for file in p:lines()do
    table.insert(self.modules,file)
    local m = file:match("[^/]*.lua$")
    local repos = require('modules/'..m:sub(0, #m - 4))
    for _,repo in pairs(repos) do
      table.insert(self.repos,repo)
    end
  end
end

local produtor = function (pack)
  pack:parse_config()
  local repos = pack.repos
  if vim.fn.filereadable(plugins_cache) == 0 then
    coroutine.resume(newConsumer,repos,1)
    return
  end
  if vim.fn.filereadable(packer_compiled) == 0 then
    coroutine.resume(newConsumer,repos,2)
    return
  end
  local f = io.open(plugins_cache,'r')
  local output = {}
  local count = 0
  for each in f:lines() do
    count = count + 1
    output[each] = count
  end
  for _,repo in pairs(repos) do
    local name = repo[1]
    if output[name] == nil then
      coroutine.resume(newConsumer,repos)
      return
    end
  end
end

local consumer = function(repos,type)
  local packer = require('packer')
  local installer = {packer.sync,packer.compile}
  local use = packer.use
  local cfg = {
    compile_path = packer_compiled
  }
  packer.init(cfg)
  packer.reset()
  local file = io.open(plugins_cache,'w+')
  for _,repo in pairs(repos) do
    file:write(repo[1]..'\n')
    use(repo)
  end
  installer[type]()
  file:close()
end

function pack:load_repos()
  local packer_dir = data_dir..'/pack/packer/opt/packer.nvim'
  local cmd = "git clone https://github.com/wbthomason/packer.nvim " ..packer_dir

  if vim.fn.has('vim_starting') then
    if not global.isdir(packer_dir) then
      os.execute(cmd)
      os.execute('mkdir -p '..data_dir..'plugin')
    end
    package.path = package.path .. ';' .. packer_dir .. '/lua/?.lua'
  end

  local newProdutor = coroutine.create(produtor)
  newConsumer = coroutine.create(consumer)
  coroutine.resume(newProdutor,pack)

  vim.api.nvim_command('filetype plugin indent on')

  if vim.fn.has('vim_starting') == 1 then
    vim.api.nvim_command('syntax enable')
  end
end

return pack
