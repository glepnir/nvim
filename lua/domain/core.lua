local options = require 'domain.options'
local global = require 'domain.global'
local dein = require 'domain.dein'
local autocmd = require 'internal.event'
local fs = require 'publibs.plfs'
local vim = vim

-- Create cache dir and subs dir
local createdir = function ()
  local data_dir = {
    global.cache_dir..'backup',
    global.cache_dir..'session',
    global.cache_dir..'swap',
    global.cache_dir..'tags',
    global.cache_dir..'undo'
  }
  -- There only check once that If cache_dir exists
  -- Then I don't want to check subs dir exists
  if not fs.is_dir(global.cache_dir) then
    os.execute("mkdir -p " .. global.cache_dir)
    for _,v in pairs(data_dir) do
      if not global.isdir(v) then
        os.execute("mkdir -p " .. v)
      end
    end
  end
end

local disable_distribution_plugins= function()
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

local leader_map = function()
  vim.g.mapleader = " "
  vim.fn.nvim_set_keymap('n',' ','',{noremap = true})
  vim.fn.nvim_set_keymap('x',' ','',{noremap = true})
end

local load_core =function()
  createdir()
  disable_distribution_plugins()
  leader_map()

  options:load_options()

  -- load my colorscheme
  require'internal.zephyr'
  dein:load_repos()

  require('internal.mapping')
  autocmd.load_autocmds()
  require('internal.eviline')
end

load_core()
