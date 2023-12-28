--Netrw lazyload
local loaded_netrw = false

vim.api.nvim_create_autocmd('FileType', {
  pattern = 'netrw',
  callback = function(args)
    vim.opt_local.stc = ''
    vim.opt_local.number = false
    local map = function(t)
      for k, v in pairs(t) do
        vim.keymap.set('n', k, v, { remap = true, buffer = args.buf })
      end
    end
    map({
      ['h'] = '<Plug>NetrwBrowseUpDir',
      ['l'] = '<Plug>NetrwLocalBrowseCheck',
      ['c'] = '<Plug>NetrwOpenFile',
      ['r'] = 'R',
      ['.'] = 'gh',
    })
  end,
})

vim.api.nvim_create_user_command('Lexplore', function()
  vim.g.netrw_banner = 0
  vim.g.netrw_winsize = math.floor((30 / vim.o.columns) * 100)
  vim.g.netrw_keepdir = 0
  vim.g.netrw_liststyle = 3
  if not loaded_netrw then
    vim.g.loaded_netrwPlugin = nil
    vim.cmd.source(vim.env.VIMRUNTIME .. '/plugin/netrwPlugin.vim')
    vim.cmd('Lexplore')
    loaded_netrw = true
    return
  end
  vim.cmd('Lexplore')
end, {
  nargs = '?',
})
