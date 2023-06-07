local api = vim.api
local nvim_create_autocmd = api.nvim_create_autocmd
local my_group = vim.api.nvim_create_augroup('GlepnirGroup', {})

nvim_create_autocmd('BufWritePre', {
  group = my_group,
  pattern = { '/tmp/*', 'COMMIT_EDITMSG', 'MERGE_MSG', '*.tmp', '*.bak' },
  command = 'setlocal noundofile',
})

nvim_create_autocmd('BufRead', {
  group = my_group,
  pattern = '*.conf',
  command = 'setlocal filetype=conf',
})

nvim_create_autocmd('TextYankPost', {
  group = my_group,
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 400 })
  end,
})

-- disable default syntax in these file.
-- when file is larged ,load regex syntax
-- highlight will cause very slow
nvim_create_autocmd('Filetype', {
  group = my_group,
  pattern = '*.c,*.cpp,*.lua,*.go,*.rs,*.py,*.ts,*.tsx',
  command = 'syntax off',
})

nvim_create_autocmd('CursorHold', {
  group = my_group,
  callback = function(opt)
    require('internal.cursorword').cursor_moved(opt.buf)
  end,
})

nvim_create_autocmd('InsertEnter', {
  group = my_group,
  once = true,
  callback = function()
    require('internal.cursorword').disable_cursorword()
    require('internal.epoch').epoch()
  end,
})

nvim_create_autocmd('BufEnter', {
  group = my_group,
  once = true,
  callback = function()
    require('keymap')
    require('internal.track').setup()
  end,
})
