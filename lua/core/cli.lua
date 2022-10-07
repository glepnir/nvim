local cli = {}
local helper = require('core.helper')

function cli:env_init()
  self.module_path = self.config_path .. '/lua/modules'
  local data_dir = helper.get_data_path()
  self.start_dir = data_dir .. '/site/pack/packer/start/'
  self.opt_dir = data_dir .. '/site/pack/packer/opt/'

  package.path = package.path
    .. ';'
    .. self.rtp
    .. '/lua/vim/?.lua;'
    .. self.module_path
    .. '/?.lua;'
  local shared = assert(loadfile(self.rtp .. '/lua/vim/shared.lua'))
  _G.vim = shared()
end

local function is_lazy(repo)
  local lazy_keyword = { 'cmd', 'opt', 'after', 'ft', 'keys', 'event', 'cond', 'lazy' }
  local keys = vim.tbl_keys(repo)
  for _, k in pairs(keys) do
    if vim.tbl_contains(lazy_keyword, k) then
      return true
    end
  end
  return false
end

function cli:get_all_repos()
  local Packer = require('core.pack').Packer
  local p = io.popen('find "' .. cli.module_path .. '" -type f')
  for file in p:lines() do
    if file:find('plugins.lua') then
      local module = file:match(cli.module_path .. '/(.+).lua$')
      require(module)
    end
  end
  p:close()

  local repos = Packer.repos

  local require_repos = {}

  local alread_in = function(repo_name)
    for _, repl in pairs(Packer.repos) do
      if repl[1] == repo_name then
        return true
      end
    end
    return false
  end

  for _, repo in pairs(repos) do
    for key, conf in pairs(repo) do
      if key ~= 'requires' then
        goto skip
      end

      if type(conf) == 'string' and not alread_in(conf) then
        table.insert(require_repos, { conf })
      end

      if type(conf) == 'table' and #conf == 1 and not vim.tbl_islist(conf) then
        if not alread_in(conf[1]) then
          if is_lazy(conf) then
            table.insert(require_repos, { conf[1], lazy = true })
          else
            table.insert(require_repos, { conf[1] })
          end
        end
      end

      if type(conf) == 'table' then
        for _, value in pairs(conf) do
          if type(value) == 'string' and not alread_in(value) then
            table.insert(require_repos, { value })
          end

          if type(value) == 'table' and not alread_in(value[1]) then
            if is_lazy(value) then
              table.insert(require_repos, { value[1], lazy = true })
            else
              table.insert(require_repos, { value[1] })
            end
          end
        end
      end
      ::skip::
    end
  end

  for _, repo in pairs(require_repos) do
    if not alread_in(repo[1]) then
      table.insert(repos, repo)
    end
  end

  return repos
end

local function scandir(directory, tbl)
  local handle = io.popen('ls ' .. directory)
  for dict in handle:lines() do
    if not dict:find('packer') then
      table.insert(tbl, directory .. dict)
    end
  end
  handle:close()
end

-- get all dictories in start_dir/opt_dir
function cli:all_repo_dicts()
  self.dictories = {}
  scandir(cli.start_dir, self.dictories)
  scandir(cli.opt_dir, self.dictories)
end

-- mark the dictory which should be remove later
local function mark_remove_dir(repo_name)
  local name_split = vim.split(repo_name, '/')
  local name = name_split[#name_split]:len() > 0 and name_split[#name_split]
    or name_split[#name_split - 1]
  for k, dict in pairs(cli.dictories) do
    if dict == cli.start_dir .. name or dict == cli.opt_dir .. name then
      table.remove(cli.dictories, k)
      break
    end
  end
end

-- remove all unisntall plugins dictories
local function remove_all_marks()
  for _, k in pairs(cli.dictories) do
    os.execute('rm -rf ' .. k)
    helper.green('Remove ' .. k .. ' success')
  end
end

local function sync_install_repo(repo_name, dir)
  local name_split = vim.split(repo_name, '/')
  if #name_split == 2 and not helper.isdir(dir .. name_split[2]) then
    helper.run_git(repo_name .. ' ' .. dir .. name_split[2], 'clone')
    helper.install_success(repo_name)
  end

  if #name_split > 2 and not helper.isdir(dir .. name_split[#name_split]) then
    os.execute('ln -s ' .. repo_name .. ' ' .. dir .. name_split[#name_split])
    helper.install_success(repo_name)
  end
end

local function update_all_repos(repo_name, dir)
  local name_split = vim.split(repo_name, '/')
  local name = name_split[#name_split]:len() > 0 and name_split[#name_split]
    or name_split[#name_split - 1]
  if helper.isdir(dir .. name) and helper.isdir(dir .. name .. '/.git/') then
    helper.run_git(dir .. name, 'pull')
    helper.green('✅ Update ' .. repo_name .. ' success')
  end
end

--install plugins
function cli:install_or_update(repo, f)
  local repo_name = repo[1]
  local dir = is_lazy(repo) and self.opt_dir or self.start_dir
  f(repo_name, dir)
end

function cli:make_sure_packer()
  helper.magenta('🔸 Download plugin management packer.nvim...')
  local packer_dir = cli.opt_dir .. 'packer.nvim'
  local packer_down_cmd = 'wbthomason/packer.nvim ' .. packer_dir
  helper.run_git(packer_down_cmd, 'clone')
  helper.install_success('Packer.nvim')
end

function cli.install()
  cli:make_sure_packer()

  os.execute('mkdir -p ' .. cli.start_dir)

  local all_repos = cli:get_all_repos()
  helper.magenta('🔸 Install ' .. #all_repos .. ' plugins...')
  for _, repo in pairs(all_repos) do
    cli:install_or_update(repo, sync_install_repo)
  end

  helper.magenta('Running compile ...')
  os.execute([[nvim --headless -c 'lua=require"core.pack".Packer:cli_compile()']])
  print('\n')
  helper.pink('🎉 Congratulations All Plugins Installed Success.')
end

-- install missed plugins
-- remove uninstall plugins
function cli.sync()
  helper.magenta('🔸 Sync plugins ...')
  local all_repos = cli:get_all_repos()
  local sync_installer = function(repo_name, dir)
    sync_install_repo(repo_name, dir)
    mark_remove_dir(repo_name)
  end
  cli:all_repo_dicts()
  for _, repo in pairs(all_repos) do
    cli:install_or_update(repo, sync_installer)
  end
  remove_all_marks()
  os.execute([[nvim --headless -c 'lua=require"core.pack".Packer:cli_compile()']])
  print('\n')
  helper.pink('🎉 Sync Complete')
end

function cli.clean()
  os.execute('rm -rf ' .. cli.start_dir)
  os.execute('rm -rf ' .. cli.opt_dir)
  helper.green('Remove Directories Success')
end

function cli.update()
  local all_repos = cli:get_all_repos()
  update_all_repos('packer.nvim', cli.opt_dir)
  for _, repo in pairs(all_repos) do
    cli:install_or_update(repo, update_all_repos)
  end
  helper.green('🎉 Update all plugins success ')
end

function cli.doctor()
  local all_repos = cli:get_all_repos()
  local max_len = 0

  for i = 1, #all_repos do
    if #all_repos[i][1] > max_len then
      max_len = #all_repos[i][1]
    end
  end

  local lazy_load, is_normal = {}, {}
  for _, repo in pairs(all_repos) do
    if is_lazy(repo) then
      table.insert(lazy_load, repo[1] .. string.rep(' ', max_len - #repo[1]) .. ' lazyload: true')
    else
      table.insert(is_normal, repo[1] .. string.rep(' ', max_len - #repo[1]) .. ' lazyload: false')
    end
  end

  helper.orange('Total plugins: ' .. #all_repos .. '  lazyload: ' .. #lazy_load)

  for _, msg in pairs(is_normal) do
    helper.magenta(msg)
  end

  for _, msg in pairs(lazy_load) do
    helper.green(msg)
  end
end

function cli:meta(arg)
  return function()
    self[arg]()
  end
end

return cli
