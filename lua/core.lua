local global = require 'global'
local options = require 'options'
local autocmd = require 'event'
local dein = require 'dein'
local map = require 'mapping'
local saga = require 'lsp.lspsaga'
local vim = vim
local M = {}

-- Create cache dir and subs dir
function M.createdir()
  local data_dir = {
    global.cache_dir..'backup',
    global.cache_dir..'session',
    global.cache_dir..'swap',
    global.cache_dir..'tags',
    global.cache_dir..'undo'
  }
  -- There only check once that If cache_dir exists
  -- Then I don't want to check subs dir exists
  if not global.isdir(global.cache_dir) then
    os.execute("mkdir -p " .. global.cache_dir)
    for _,v in pairs(data_dir) do
      if not global.isdir(v) then
        os.execute("mkdir -p " .. v)
      end
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
  vim.fn.nvim_set_keymap('n',' ','',{noremap = true})
  vim.fn.nvim_set_keymap('x',' ','',{noremap = true})
end

function M.load_core()
  M.createdir()
  M.disable_distribution_plugins()
  M.leader_map()

  local ops = options:new()
  ops:load_options()
  -- load my colorscheme
  require'zephyr'

  local d = dein:new()
  d:load_repos()

  map.load_mapping()
  autocmd.load_autocmds()
  require 'spaceline'
  saga.create_saga_augroup()
end

M.load_core()
