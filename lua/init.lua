require 'global'
require 'options'
require 'event'
require 'dein'
require 'mapping'

local api = vim.api
local M = {}

function M.createdir()
  local data_dir = {cache_dir..'backup',cache_dir..'session',cache_dir..'swap',cache_dir..'tags',cache_dir..'undo'}
  if not isdir(cache_dir) then
    os.execute("mkdir -p " .. cache_dir)
  end
  for k,v in pairs(data_dir) do
    if not isdir(v) then
      os.execute("mkdir -p " .. v)
    end
  end
end

function M.disable_distribution_plugins()
  vim.g.loaded_gzip              = 1
  vim.g.loaded_tar               = 1
  vim.g.loaded_tarPlugin         = 1
  vim.g.loaded_zip               = 1
  vim.g.loaded_zipPlugin         = 1
  vim.g.loaded_getscript         = 1
  vim.g.loaded_getscriptPlugin   = 1
  vim.g.loaded_vimball           = 1
  vim.g.loaded_vimballPlugin     = 1
  vim.g.loaded_matchit           = 1
  vim.g.loaded_matchparen        = 1
  vim.g.loaded_2html_plugin      = 1
  vim.g.loaded_logiPat           = 1
  vim.g.loaded_rrhelper          = 1
  vim.g.loaded_netrw             = 1
  vim.g.loaded_netrwPlugin       = 1
  vim.g.loaded_netrwSettings     = 1
  vim.g.loaded_netrwFileHandlers = 1
end

function M.leader_map()
  vim.g.mapleader = " "
  vim.g.maplocalleader = ";"
  vim.api.nvim_set_keymap('n',' ','',{noremap = true})
  vim.api.nvim_set_keymap('x',' ','',{noremap = true})
  vim.api.nvim_set_keymap('n',';','',{noremap = true})
  vim.api.nvim_set_keymap('x',';','',{noremap = true})
end

function M.load_core()
  M.createdir()
  M.disable_distribution_plugins()
  M.leader_map()

  ops = options:new()
  ops:load_options()

  dein = dein:new()
  dein:load_repos()

  autocmds.load_autocmds()

  map = mapping:new()
  map:load_mapping()

  vim.fn['theme#theme_init']()
end

M.load_core()
