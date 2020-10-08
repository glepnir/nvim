local global = require('global')

local enhance = {
  {'kristijanhusak/vim-dadbod-ui',
   cmd = {'DBUIToggle','DBUIAddConnection','DBUI','DBUIFindBuffer','DBUIRenameBuffer'},
   requires = 'tpope/vim-dadbod',
   config = function()
       vim.g.db_ui_show_help = 0
       vim.g.db_ui_win_position = 'left'
       vim.g.db_ui_use_nerd_fonts = 1
       vim.d.db_ui_winwidth = 35
       vim.g.db_ui_save_location = global.cache_dir ..'db_ui_queries'
       vim.g.dbs = vim.fn['initself#load_db_from_env']()
   end
   };
   {'rhysd/accelerated-jk', keys = 'j'};
   {'itchyny/vim-cursorword',
    event = {'BufReadPost','BufNewFile'},
    config = function()
      vim.api.nvim_command('augroup user_plugin_cursorword')
      vim.api.nvim_command('autocmd!')
      vim.api.nvim_command('autocmd FileType defx,denite,fern,clap,vista let b:cursorword = 0')
      vim.api.nvim_command('autocmd WinEnter * if &diff || &pvw | let b:cursorword = 0 | endif')
      vim.api.nvim_command('autocmd InsertEnter * let b:cursorword = 0')
      vim.api.nvim_command('autocmd InsertLeave * let b:cursorword = 1')
      vim.api.nvim_command('augroup END')
    end
   };
   {'hrsh7th/vim-eft',config = function () vim.g.eft_ignorecase = true end}
}

return enhance
