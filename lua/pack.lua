local pack = {}
local global = require('global')
local cache_file = global.cache_dir..'cache_size.txt'

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

function pack:load_repos()
  local plugin_dir = os.getenv("HOME")..'/.cache/vim/plugins'
  local packer_dir = plugin_dir .. '/pack/packer/start/packer.nvim'
  local cmd = "git clone https://github.com/wbthomason/packer.nvim " ..packer_dir
  if vim.fn.has('vim_starting') then
    if not global.isdir(packer_dir) then
      os.execute(cmd)
    end
    vim.o.packpath = vim.o.packpath .. ',' .. plugin_dir
    package.path = package.path .. ';' .. plugin_dir .. '/pack/packer/start/packer.nvim/lua/?.lua'
  end

  local newProdutor

  local produtor = function ()
    local status = 0
    if vim.fn.filereadable(cache_file) == 0 then
      status = 1
      coroutine.yield(status)
      return
    end
    -- TODO:compare repo file size to watch plugins is added or deleted?
  end

  local consumer = function(pack)
    local _,status = coroutine.resume(newProdutor)
    if status ~= 0 then
      local packer = require('packer')
      local use = packer.use
      packer.init({package_root = plugin_dir..'/pack'})
      packer.reset()
      pack:parse_config()
      for _,repo in pairs(pack.repos) do
        use(repo)
      end
      packer.install()
    end
  end

  newProdutor = coroutine.create(produtor)
  consumer(pack)

  vim.api.nvim_command('filetype plugin indent on')

  if vim.fn.has('vim_starting') == 1 then
    vim.api.nvim_command('syntax enable')
  end
end

return pack
