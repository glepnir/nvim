local api = vim.api
local au = api.nvim_create_autocmd
local group = vim.api.nvim_create_augroup('GlepnirGroup', {})

au('BufWritePre', {
  group = group,
  pattern = { '/tmp/*', 'COMMIT_EDITMSG', 'MERGE_MSG', '*.tmp', '*.bak' },
  command = 'setlocal noundofile',
})

au('TextYankPost', {
  group = group,
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 400 })
  end,
})

au('BufEnter', {
  group = group,
  once = true,
  callback = function()
    require('keymap')
    require('internal.buffer')
    vim.cmd.packadd('nohlsearch')
  end,
  desc = 'Lazy load my keymap and buffer relate commands and defaul opt plugins',
})

--disable diagnostic in neovim test file *_spec.lua
au('FileType', {
  group = group,
  pattern = 'lua',
  callback = function(opt)
    local fname = vim.api.nvim_buf_get_name(opt.buf)
    if fname:find('%w_spec%.lua') then
      vim.diagnostic.enable(not vim.diagnostic.is_enabled({ bufnr = opt.buf }))
    end
  end,
})

--for alacritty only
au('ExitPre', {
  group = group,
  command = 'set guicursor=a:ver90',
  desc = 'Set cursor back to beam when leaving Neovim.',
})

au('TermOpen', {
  group = group,
  callback = function()
    vim.opt_local.stc = ''
    vim.wo.number = false
    vim.cmd.startinsert()
  end,
})

au('InsertEnter', {
  group = group,
  callback = function()
    require('internal.pairs').setup({})
  end,
})

au('FileType', {
  pattern = 'netrw',
  callback = function()
    local map = function(lhs, rhs, remap, desc)
      vim.keymap.set('n', lhs, rhs, { buffer = true, remap = remap, desc = desc })
    end
    vim.wo.stc = ''
    local function split(cmd)
      return function()
        vim.cmd(('%s %s'):format(cmd, vim.fn.expand('<cfile>')))
      end
    end
    map('r', 'R', true, 'rename file')
    map('l', '<CR>', true, 'open directory or file')
    map('.', 'gh', true, 'toggle dotfiles')
    map('H', 'u', true, 'go back')
    map('h', '-^', true, 'go up')
    map('c', '%', true, 'create file')
    map('s', split('vsplit'), false, 'vsplit open')
    map('v', split('split'), false, 'split open')
  end,
})
