local fn,uv,api = vim.fn,vim.loop,vim.api
local vim_path = vim.fn.stdpath('config')
local data_dir = string.format('%s/site/',vim.fn.stdpath('data'))
local modules_dir = vim_path .. '/lua/modules'
local packer_compiled = data_dir..'lua/packer_compiled.lua'
local packer = nil

local Packer = {}
Packer.__index = Packer

function Packer:load_plugins()
  self.repos = {}

  local get_plugins_list = function ()
    local list = {}
    local tmp = vim.split(fn.globpath(modules_dir,'*/plugins.lua'),'\n')
    for _,f in ipairs(tmp) do
      list[#list+1] = f:sub(#modules_dir - 6,-1)
    end
    return list
  end

  local plugins_file = get_plugins_list()
  for _,m in ipairs(plugins_file) do
    local repos = require(m:sub(0,#m-4))
    for repo,conf in pairs(repos) do
      self.repos[#self.repos+1] = vim.tbl_extend('force',{repo},conf)
    end
  end
end

function Packer:load_packer()
  if not packer then
    api.nvim_command('packadd packer.nvim')
    packer = require('packer')
  end
  packer.init({
    compile_path = packer_compiled,
    git = { clone_timeout = 120 },
    disable_commands = true
  })
  packer.reset()
  local use = packer.use
  self:load_plugins()
  use {"wbthomason/packer.nvim", opt = true }
  for _,repo in ipairs(self.repos) do
    use(repo)
  end
end

function Packer:init_ensure_plugins()
  local packer_dir = data_dir..'pack/packer/opt/packer.nvim'
  local state = uv.fs_stat(packer_dir)
  if not state then
    local cmd = "!git clone https://github.com/wbthomason/packer.nvim " ..packer_dir
    api.nvim_command(cmd)
    uv.fs_mkdir(data_dir..'lua',511,function()
      assert("make compile path dir faield")
    end)
    self:load_packer()
    packer.install()
  end
end

local plugins = setmetatable({}, {
  __index = function(_, key)
    if not packer then
      Packer:load_packer()
    end
    return packer[key]
  end
})

function plugins.ensure_plugins()
  Packer:init_ensure_plugins()
end

function plugins.compile_notify()
  plugins.compile()
  vim.notify('Compile Done!','info',{ title = 'Packer' })
end

function plugins.auto_compile()
  local file = vim.fn.expand('%:p')
  if file:match('plugins.lua') then
    plugins.clean()
    return
  end
  if file:match(vim_path) then
    plugins.compile_notify()
  end
  require('packer_compiled')
end

function plugins.load_compile()
  if vim.fn.filereadable(packer_compiled) == 1 then
    require('packer_compiled')
  else
    assert('Missing packer compile file Run PackerCompile Or PackerInstall to fix')
  end

  vim.cmd [[command! PackerCompile lua require('core.pack').compile_notify()]]
  vim.cmd [[command! PackerInstall lua require('core.pack').install()]]
  vim.cmd [[command! PackerUpdate lua require('core.pack').update()]]
  vim.cmd [[command! PackerSync lua require('core.pack').sync()]]
  vim.cmd [[command! PackerClean lua require('core.pack').clean()]]
  vim.cmd [[command! PackerStatus  lua require('packer').status()]]

  api.nvim_create_autocmd("BufWritePost",{
    pattern = "*.lua",
    callback = function()
      plugins.auto_compile()
    end,
    desc = "Auto Compile the neovim config which write in lua",
  })
end

return plugins
