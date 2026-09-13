local fname = vim.fn.expand('%:p')

if fname:match('.*_spec%.lua$') then
  vim.api.nvim_create_user_command('NvimRunTest', function()
    local cmd = ('TEST_FILE=%s make test'):format(fname)
    require('run').run(cmd, vim.api.nvim_get_current_buf())
  end)
end
