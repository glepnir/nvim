local cli = {}
local helper = require('core.helper')

function cli:env_init()
  self.module_path = self.config_path .. '/lua/modules'
  local data_dir = helper.get_data_path()
  self.lazy_dir = data_dir .. '/lazy'

  package.path = package.path
    .. ';'
    .. self.rtp
    .. '/lua/vim/?.lua;'
    .. self.module_path
    .. '/?.lua;'
  local shared = assert(loadfile(self.rtp .. '/lua/vim/shared.lua'))
  _G.vim = shared()
end

local function get_all_modules()
  local p = io.popen('find "' .. cli.module_path .. '" -type d')
  if not p then
    return
  end

  for dict in p:lines() do
    print(dict)
  end
end

function cli:get_all_repos()
  local pack = require('core.pack')
  local p = io.popen('find "' .. cli.module_path .. '" -type f')
  if not p then
    return
  end

  for file in p:lines() do
    if file:find('plugins.lua') then
      local module = file:match(cli.module_path .. '/(.+).lua$')
      require(module)
    end
  end
  p:close()

  return pack.repos
end

function cli:install_or_update(repo)
  local repo_name = repo[1]
  if repo.dev then
    helper.pink('\t🥯 Skip local plugin ' .. repo_name)
    return
  end

  local name = vim.split(repo_name, '/')[2]
  local target = self.lazy_dir .. helper.path_sep .. name
  local type = helper.isdir(target) and 'pull' or 'clone'
  helper.run_git(target, type)
end

function cli:boot_strap()
  helper.magenta('🔸 Search plugin management lazy.nvim in local')
  if helper.isdir(self.lazy_dir) then
    helper.green('🔸 Found lazy.nvim skip download')
    return
  end
  helper.run_git('folke/lazy.nvim ' .. self.lazy_dir, 'clone')
  helper.install_success('lazy.nvim')
end

function cli.sync()
  cli:boot_strap()

  local all_repos = cli:get_all_repos()
  helper.magenta('🔸 Sync plugins...')
  for _, repo in pairs(all_repos or {}) do
    cli:install_or_update(repo)
    if repo.dependencies then
      for _, v in pairs(repo.dependencies) do
        if type(v) == 'string' then
          v = { v }
        end
        cli:install_or_update(v)
      end
    end
  end
  helper.pink('🎉 Congratulations All Plugins Installed Success.')
end

function cli.clean()
  os.execute('rm -rf ' .. cli.lazy_dir)
end

function cli.doctor()
  local lazy_keyword = {
    'keys',
    'ft',
    'cmd',
    'event',
    'lazy',
  }

  local function generate_node(tbl, list)
    local node = tbl[1]
    list[node] = {}
    list[node].type = tbl.dev and 'Local Plugin' or 'Remote Plugin'

    local check_lazy = function(t, data)
      vim.tbl_filter(function(k)
        if vim.tbl_contains(lazy_keyword, k) then
          data.load = type(t[k]) == 'table' and table.concat(t[k], ',') or t[k]
          return true
        end
        return false
      end, vim.tbl_keys(t))
    end

    check_lazy(tbl, list[node])

    if tbl.dependencies then
      for _, v in pairs(tbl.dependencies) do
        if type(v) == 'string' then
          v = { v }
        end

        list[v[1]] = {
          from_depend = true,
          load_after = node,
        }

        list[v[1]].type = v.dev and 'Local Plugin' or 'Remote Plugin'
        check_lazy(v, list[v[1]])
      end
    end
  end

  local all_repos = cli:get_all_repos()
  local list = {}
  for _, data in pairs(all_repos or {}) do
    if type(data) == string then
      data = { data }
    end
    generate_node(data, list)
  end

  helper.magenta('Total: ' .. vim.tbl_count(list) .. ' Plugins')
  for k, v in pairs(list) do
    local msg = k .. ' ' .. v.type
    if v.load then
      msg = msg .. ' Load By: ' .. v.load
    end

    if v.from_depend then
      msg = msg .. ' Depend on: ' .. v.load_after
    end
    helper.green(msg)
  end
end

function cli.modules()
  get_all_modules()
end

function cli:meta(arg)
  return function()
    self[arg]()
  end
end

return cli
