local global = require 'domain.global'
local fs = require 'publibs.plfs'
local vim = vim
local dein  = setmetatable({}, { __index = { repos = {},config_files = {} } })

function dein:parse_config()
  local cmd = nil
  if global.is_mac then
    cmd = [[ruby -e 'require "json"; require "yaml"; print JSON.generate YAML.load $stdin.read']]
  elseif global.is_linux then
    cmd = [[python -c 'import sys,yaml,json; y=yaml.safe_load(sys.stdin.read()); print(json.dumps(y))']]
  end
  local p = io.popen('find "'..global.modules_dir..'" -name "*.yaml"')
  for file in p:lines() do
    table.insert(self.config_files,vim.inspect(file))
    local cfg = vim.api.nvim_eval(vim.fn.system(cmd,fs.readAll(file)))
    for _,v in pairs(cfg) do
      table.insert(self.repos,v)
    end
  end
  table.insert(self.config_files,vim.fn.expand("<sfile>"))
end

function dein:load_repos()
  local dein_path = global.cache_dir .. 'dein'
  local dein_dir = global.cache_dir ..'dein/repos/github.com/Shougo/dein.vim'
  local cmd = "git clone https://github.com/Shougo/dein.vim " .. dein_dir

  if vim.fn.has('vim_starting') then
    vim.api.nvim_set_var('dein#auto_recache',1)
    vim.api.nvim_set_var('dein#install_max_processes',12)
    vim.api.nvim_set_var('dein#install_progress_type',"title")
    vim.api.nvim_set_var('dein#enable_notification',1)
    vim.api.nvim_set_var('dein#lazy_rplugins',1)
    vim.api.nvim_set_var('dein#install_log_filename',global.cache_dir ..'dein.log')

    if not vim.o.runtimepath:match('/dein.vim') then
      if not fs.is_dir(dein_dir) then
        os.execute(cmd)
      end
      vim.o.runtimepath = vim.o.runtimepath ..','..dein_dir
    end
  end

  if vim.fn['dein#load_state'](dein_path) == 1 then
    self:parse_config()
    vim.fn['dein#begin'](dein_path,self.config_files)
    for _,cfg in pairs(self.repos) do
      vim.fn['dein#add'](cfg.repo,cfg)
    end
--     vim.fn['dein#local']('~/workstation/vim/lspsaga', {frozen= 1, merged= 0 })
    vim.fn['dein#end']()
    vim.fn['dein#save_state']()

    if vim.fn['dein#check_install']() == 1 then
      vim.fn['dein#install']()
    end
  end

  vim.api.nvim_command('filetype plugin indent on')

  if vim.fn.has('vim_starting') == 1 then
    vim.api.nvim_command('syntax enable')
  end

  vim.fn['dein#call_hook']('source')
  vim.fn['dein#call_hook']('post_source')
end

return dein
