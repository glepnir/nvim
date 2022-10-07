local uv, api = vim.loop, vim.api
local helper = require('core.helper')
local vim_path = helper.get_config_path()
local data_dir = string.format('%s/site/', helper.get_data_path())
local modules_dir = vim_path .. '/lua/modules'
local packer_compiled = data_dir .. 'lua/packer_compiled.lua'
local packer = nil

local Packer = {}
Packer.__index = Packer

function Packer:load_plugins()
  self.repos = {}

  local get_plugins_list = function()
    local list = {}
    local tmp = vim.split(vim.fn.globpath(modules_dir, '*/plugins.lua'), '\n')
    for _, f in ipairs(tmp) do
      list[#list + 1] = string.match(f, 'lua/(.+).lua$')
    end
    return list
  end

  local plugins_file = get_plugins_list()
  for _, m in ipairs(plugins_file) do
    require(m)
  end
end

function Packer:load_packer()
  if not packer then
    api.nvim_command('packadd packer.nvim')
    packer = require('packer')
  end
  packer.init({
    compile_path = packer_compiled,
    disable_commands = true,
    display = {
      open_fn = require('packer.util').float,
      working_sym = 'ﰭ',
      error_sym = '',
      done_sym = '',
      removed_sym = '',
      moved_sym = 'ﰳ',
    },
    git = { clone_timeout = 120 },
  })
  packer.reset()
  local use = packer.use
  self:load_plugins()
  use({ 'wbthomason/packer.nvim', opt = true })
  for _, repo in ipairs(self.repos) do
    use(repo)
  end
end

function Packer:init_ensure_plugins()
  local packer_dir = data_dir .. 'pack/packer/opt/packer.nvim'
  local state = uv.fs_stat(packer_dir)
  if not state then
    local cmd = '!git clone https://github.com/wbthomason/packer.nvim ' .. packer_dir
    api.nvim_command(cmd)
    uv.fs_mkdir(data_dir .. 'lua', 511, function()
      assert('make compile path dir failed')
    end)
    self:load_packer()
    packer.sync()
  end
end

function Packer:cli_compile()
  self:load_packer()
  packer.compile()
  vim.defer_fn(function()
    vim.cmd('q')
  end, 1000)
end

local plugins = setmetatable({}, {
  __index = function(_, key)
    if key == 'Packer' then
      return Packer
    end
    if not packer then
      Packer:load_packer()
    end
    return packer[key]
  end,
})

function plugins.ensure_plugins()
  Packer:init_ensure_plugins()
end

function plugins.package(repo)
  if not Packer.repos then
    Packer.repos = {}
  end
  table.insert(Packer.repos, repo)
end

function plugins.auto_compile()
  local file = api.nvim_buf_get_name(0)
  if not file:match(vim_path) then
    return
  end

  if file:match('plugins.lua') then
    plugins.clean()
  end
  plugins.compile()
  require('packer_compiled')
end

function plugins.load_compile()
  if vim.fn.filereadable(packer_compiled) == 1 then
    require('packer_compiled')
  end

  local cmds = {
    'Compile',
    'Install',
    'Update',
    'Sync',
    'Clean',
    'Status',
  }
  for _, cmd in ipairs(cmds) do
    api.nvim_create_user_command('Packer' .. cmd, function()
      require('core.pack')[string.lower(cmd)]()
    end, {})
  end

  local PackerHooks = vim.api.nvim_create_augroup('PackerHooks', { clear = true })
  vim.api.nvim_create_autocmd('User', {
    group = PackerHooks,
    pattern = 'PackerCompileDone',
    callback = function()
      vim.notify('Compile Done!', vim.log.levels.INFO, { title = 'Packer' })
      dofile(vim.env.MYVIMRC)
    end,
  })

  api.nvim_create_autocmd('VimLeave', {
    pattern = '*.lua',
    callback = function()
      plugins.auto_compile()
    end,
    desc = 'Auto Compile the neovim config which write in lua',
  })
end

return plugins
