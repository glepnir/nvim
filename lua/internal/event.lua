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

nvim_create_autocmd('BufEnter', {
  group = my_group,
  once = true,
  callback = function()
    require('keymap')
    require('internal.track').setup()
  end,
})

-- local orig_color
-- vim.api.nvim_create_autocmd({ 'CmdlineEnter', 'CmdLineChanged', 'CmdlineLeave' }, {
--   group = vim.api.nvim_create_augroup('colorscheme preview', {}),
--   desc = 'colorscheme preview when using :colorscheme command',
--   callback = function(data)
--     if vim.fn.getcmdtype() ~= ':' then
--       return
--     end
--     local cmd, arg = unpack(vim.split(vim.fn.getcmdline(), '%s+'))
--     if not vim.startswith(cmd, 'color') or not arg then
--       return
--     end
--     if data.event == 'CmdlineEnter' then
--       orig_color = vim.g.colors_name
--     elseif data.event == 'CmdlineLeave' then
--       vim.cmd.color(orig_color)
--     else
--       if not pcall(vim.cmd.color, { arg, mods = { noautocmd = true } }) then
--         vim.cmd.color(orig_color)
--       end
--       vim.cmd.redraw()
--     end
--   end,
-- })

-- actually I don't notice the cursor word
-- nvim_create_autocmd('CursorHold', {
--   group = my_group,
--   callback = function(opt)
--     require('internal.cursorword').cursor_moved(opt.buf)
--   end,
-- })

-- nvim_create_autocmd('InsertEnter', {
--   group = my_group,
--   once = true,
--   callback = function()
--     require('internal.cursorword').disable_cursorword()
--   end,
-- })
