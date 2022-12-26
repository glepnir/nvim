local uv, api, fn = vim.loop, vim.api, vim.fn
local helper = require('core.helper')

local pack = {}
pack.__index = pack

function pack:load_modules_packages()
  local modules_dir = helper.get_config_path() .. '/lua/modules'
  self.repos = {}

  local get_plugins_list = function()
    local list = {}
    local tmp = vim.split(fn.globpath(modules_dir, '*/plugins.lua'), '\n')
    for _, f in ipairs(tmp) do
      list[#list + 1] = string.match(f, 'lua/(.+).lua$')
    end
    return list
  end

  local plugins_file = get_plugins_list()
  local disable_modules = {}

  if fn.exists('g:disable_modules') == 1 then
    disable_modules = vim.split(vim.g.disable_modules, ',')
  end

  for _, m in ipairs(plugins_file) do
    if not vim.tbl_contains(disable_modules, m) then
      require(m)
    end
  end
end

function pack:boot_strap()
  local lazy_path = string.format('%s/lazy/lazy.nvim', helper.get_data_path())
  local state = uv.fs_stat(lazy_path)
  if not state then
    local cmd = '!git clone https://github.com/folke/lazy.nvim ' .. lazy_path
    api.nvim_command(cmd)
  end
  vim.opt.runtimepath:prepend(lazy_path)
  local lazy = require('lazy')
  local opts = {
    lockfile = helper.get_data_path() .. '/lazy-lock.json',
    dev = { path = '~/Workspace' },
  }
  self:load_modules_packages()
  lazy.setup(self.repos, opts)
end

function pack.package(repo)
  if not pack.repos then
    pack.repos = {}
  end
  table.insert(pack.repos, repo)
end

return pack
