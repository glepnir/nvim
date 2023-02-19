local api = vim.api
local my_group = vim.api.nvim_create_augroup('GlepnirGroup', {})

api.nvim_create_autocmd({ 'BufWritePre' }, {
  group = my_group,
  pattern = { '/tmp/*', 'COMMIT_EDITMSG', 'MERGE_MSG', '*.tmp', '*.bak' },
  command = 'setlocal noundofile',
})

api.nvim_create_autocmd('BufRead', {
  group = my_group,
  pattern = '*.conf',
  command = 'setlocal filetype=conf',
})

api.nvim_create_autocmd('TextYankPost', {
  group = my_group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 400 })
  end,
})

-- disable default syntax in these file.
-- when file is larged ,load regex syntax
-- highlight will cause very slow
api.nvim_create_autocmd('Filetype', {
  group = my_group,
  pattern = '*.c,*.cpp,*.lua,*.go,*.rs,*.py,*.ts,*.tsx',
  command = 'syntax off',
})

api.nvim_create_autocmd({ 'CursorHold' }, {
  pattern = '*',
  callback = function(opt)
    require('internal.cursorword').cursor_moved(opt.buf)
  end,
})

api.nvim_create_autocmd({ 'InsertEnter' }, {
  pattern = '*',
  callback = function()
    require('internal.cursorword').disable_cursorword()
    require('internal.epoch').epoch()
  end,
})

--disable diagnostic in neovim test file *_spec.lua
api.nvim_create_autocmd('FileType', {
  pattern = 'lua',
  callback = function(opt)
    local fname = api.nvim_buf_get_name(opt.buf)
    if fname:find('%w_spec%.lua') then
      vim.diagnostic.disable(opt.buf)
    end
  end,
})
