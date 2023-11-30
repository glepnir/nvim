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

-- hack with my tmux config
nvim_create_autocmd('BufRead', {
  callback = function(data)
    if vim.fn.getenv('TMUX') == 1 then
      return
    end

    vim.defer_fn(function()
      local fname = api.nvim_buf_get_name(data.buf)
      fname = fname:sub(#vim.env.HOME + 2)
      vim.system({ 'tmux', 'set', '@path', fname }, { text = true }, function(obj)
        if obj.stderr then
          print(obj.stderr)
        end
      end)
    end, 0)

    nvim_create_autocmd('VimLeave', {
      callback = function()
        vim.system({ 'tmux', 'set', '@path', 0 }, { text = true }, function(obj)
          if obj.stderr then
            print(obj.stderr)
          end
        end)
      end,
    })
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
