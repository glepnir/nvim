local api = vim.api
local au = api.nvim_create_autocmd
local my_group = vim.api.nvim_create_augroup('GlepnirGroup', {})

au('BufWritePre', {
  group = my_group,
  pattern = { '/tmp/*', 'COMMIT_EDITMSG', 'MERGE_MSG', '*.tmp', '*.bak' },
  command = 'setlocal noundofile',
})

au('BufRead', {
  group = my_group,
  pattern = '*.conf',
  command = 'setlocal filetype=conf',
})

au('TextYankPost', {
  group = my_group,
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 400 })
  end,
})

au('BufEnter', {
  group = my_group,
  once = true,
  callback = function()
    require('keymap')
    require('internal.track').setup()
  end,
})
