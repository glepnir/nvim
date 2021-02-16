local config = {}

function config.delimimate()
  vim.g.delimitMate_expand_cr = 0
  vim.g.delimitMate_expand_space = 1
  vim.g.delimitMate_smart_quotes = 1
  vim.g.delimitMate_expand_inside_quotes = 0
  vim.api.nvim_command('au FileType markdown let b:delimitMate_nesting_quotes = ["`"]')
end

function config.nvim_colorizer()
  require 'colorizer'.setup {
    css = { rgb_fn = true; };
    scss = { rgb_fn = true; };
    sass = { rgb_fn = true; };
    stylus = { rgb_fn = true; };
    vim = { names = true; };
    tmux = { names = false; };
    'javascript';
    'javascriptreact';
    'typescript';
    'typescriptreact';
    html = {
      mode = 'foreground';
    }
  }
end

function config.vim_cursorwod()
  vim.api.nvim_command('augroup user_plugin_cursorword')
  vim.api.nvim_command('autocmd!')
  vim.api.nvim_command('autocmd FileType defx,denite,fern,clap,vista let b:cursorword = 0')
  vim.api.nvim_command('autocmd WinEnter * if &diff || &pvw | let b:cursorword = 0 | endif')
  vim.api.nvim_command('autocmd InsertEnter * let b:cursorword = 0')
  vim.api.nvim_command('autocmd InsertLeave * let b:cursorword = 1')
  vim.api.nvim_command('augroup END')
end

function config.vim_signify()
  vim.g.signify_sign_add = '▋'
  vim.g.signify_sign_change = '▋'
  vim.g.signify_sign_delete = '▋'
  vim.g.signify_sign_delete_first_line = '▘'
  vim.g.signify_sign_show_count = 0
end

function config.vim_niceblock()
  vim.api.nvim_command('silent! xmap I <Plug>(niceblock-I)')
  vim.api.nvim_command('silent! xmap gI <Plug>(niceblock-gI)')
  vim.api.nvim_command('silent! xmap A  <Plug>(niceblock-A)')
end

function config.vim_smartchar()
  vim.api.nvim_command("autocmd FileType go inoremap <buffer><expr> ; smartchr#loop(':=',';')")
end

return config
