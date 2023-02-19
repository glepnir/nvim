local api = vim.api
local my_group = vim.api.nvim_create_augroup('GlepnirGroup', {})

api.nvim_create_autocmd({ 'BufWritePre' }, {
  group = my_group,
  pattern = { '/tmp/*', 'COMMIT_EDITMSG', 'MERGE_MSG', '*.tmp', '*.bak' },
  callback = function()
    vim.opt_local.undofile = false
  end,
})

api.nvim_create_autocmd('BufRead', {
  group = my_group,
  pattern = '*.conf',
  callback = function()
    api.nvim_buf_set_option(0, 'filetype', 'conf')
  end,
})

api.nvim_create_autocmd('TextYankPost', {
  group = my_group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 400 })
  end,
})

api.nvim_create_autocmd({ 'WinEnter', 'BufEnter', 'InsertLeave' }, {
  group = my_group,
  pattern = '*',
  callback = function()
    if vim.bo.filetype ~= 'dashboard' and not vim.opt_local.cursorline:get() then
      vim.opt_local.cursorline = true
    end
  end,
})

api.nvim_create_autocmd({ 'WinLeave', 'BufLeave', 'InsertEnter' }, {
  group = my_group,
  pattern = '*',
  callback = function()
    if vim.bo.filetype ~= 'dashboard' and vim.opt_local.cursorline:get() then
      vim.opt_local.cursorline = false
    end
  end,
})

-- disable default syntax in these file.
-- when file is larged ,load regex syntax
-- highlight will cause very slow
api.nvim_create_autocmd('Filetype', {
  group = my_group,
  pattern = '*.c,*.cpp,*.lua,*.go,*.rs,*.py,*.ts,*.tsx',
  callback = function()
    vim.cmd('syntax off')
  end,
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
