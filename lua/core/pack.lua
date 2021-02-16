local fn,uv,api = vim.fn,vim.loop,vim.api
local vim_path = require('core.global').vim_path
local modules_dir = vim_path .. '/lua/modules'
local data_dir = string.format('%s/site/',vim.fn.stdpath('data'))
local packer_compiled = data_dir..'plugin/packer_compiled.vim'
local packer = nil

local Packer = {}
Packer.__index = Packer

function Packer:load_plugins()
  self.repos = {}
  local get_plugins = function()
    local list = {}
    local tmp = vim.split(fn.globpath(modules_dir,'*/plugins.lua'),'\n')
    for _,f in ipairs(tmp) do
      list[#list+1] = f:sub(#modules_dir - 6,-1)
    end
    return list
  end

  local plugins_file = get_plugins()
  for _,m in ipairs(plugins_file) do
    local repos = require(m:sub(0,#m-4))
    for repo,conf in pairs(repos) do
      self.repos[#self.repos+1] = vim.tbl_extend('force',{repo},conf)
    end
  end
end

function Packer:init_ensure_plugins()
  local packer_dir = data_dir..'pack/packer/opt/packer.nvim'
  local state = uv.fs_stat(packer_dir)
  if not state then
    local cmd = "!git clone https://github.com/wbthomason/packer.nvim " ..packer_dir
    api.nvim_command(cmd)
    uv.fs_mkdir(data_dir..'plugin',511,function()
      assert("make compile path dir faield")
    end)
  end

  api.nvim_command('packadd packer.nvim')
  self:load_plugins()
  packer = require('packer')
  local use = packer.use
  packer.init({
    compile_path = packer_compiled,
    git = { clone_timeout = 120 },
    disable_commands = true
  })
  packer.reset()
  for _,repo in ipairs(self.repos) do
    use(repo)
  end

  api.nvim_command('filetype plugin indent on')
  if fn.has('vim_starting') == 1 then
    api.nvim_command('syntax enable')
  end
end

local plugins = setmetatable({}, {
  __index = function(_, key)
    Packer:init_ensure_plugins()
    return packer[key]
  end
})

return plugins
