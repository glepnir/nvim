local uv, api, fn = vim.uv, vim.api, vim.fn
local pack = {}
pack.__index = pack

function pack:load_modules_packages()
  ---@diagnostic disable-next-line: param-type-mismatch
  local modules_dir = vim.fs.joinpath(self.config_path, 'lua', 'modules')
  self.repos = {}

  local list = vim.fs.find('package.lua', { path = modules_dir, type = 'file', limit = 10 })
  if #list == 0 then
    return
  end

  vim.iter(list):map(function(f)
    local _, pos = f:find(modules_dir)
    f = f:sub(pos - 6, #f - 4)
    require(f)
  end)
end

function pack:boot_strap()
  self.data_path = fn.stdpath('data')
  self.config_path = fn.stdpath('config')
  ---@diagnostic disable-next-line: param-type-mismatch
  local lazy_path = vim.fs.joinpath(self.data_path, 'lazy', 'lazy.nvim')
  local state = uv.fs_stat(lazy_path)
  if not state then
    local cmd = '!git clone https://github.com/folke/lazy.nvim ' .. lazy_path
    api.nvim_command(cmd)
  end
  vim.opt.runtimepath:prepend(lazy_path)
  self:load_modules_packages()
  --TODO(glepnir): remove lazy it sourced the fil which in ftplugin twice !!!
  require('lazy').setup(self.repos, {
    ---@diagnostic disable-next-line: param-type-mismatch
    lockfile = vim.fs.joinpath(self.data_path, 'lazy-lock.json'),
    dev = { path = '~/workspace' },
  })
end

_G.packadd = function(repo)
  if not pack.repos then
    pack.repos = {}
  end

  pack.repos[#pack.repos + 1] = repo
end

return pack
