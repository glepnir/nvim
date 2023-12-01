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

local function set_tmux_bar()
  vim.defer_fn(function()
    local fname = api.nvim_buf_get_name(0)
    fname = fname:sub(#vim.env.HOME + (fname:find('workspace') and 12 or 2))
    if #fname == 0 then
      return
    end
    vim.system({ 'tmux', 'set', '@path', fname }, { text = true }, function(obj)
      if obj.stderr then
        print(obj.stderr)
      end
    end)
  end, 0)
end

-- hack with my tmux config
au('VimLeave', {
  group = my_group,
  callback = function()
    vim.system({ 'tmux', 'set', '@path', '0' }, { text = true }, function() end)
  end,
})

au('BufEnter', {
  group = my_group,
  callback = function()
    if vim.fn.getenv('TMUX') == 1 then
      return
    end
    set_tmux_bar()

    if #api.nvim_get_autocmds({ group = my_group, event = { 'FocusGained' } }) == 0 then
      au('FocusGained', {
        group = my_group,
        callback = function()
          set_tmux_bar()
        end,
      })
    end
  end,
})

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
