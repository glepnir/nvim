vim.api.nvim_create_user_command('NvimRunTest', function(args)
  local target = args.args
  local cwd = assert(vim.uv.cwd())
  if target == '' then
    target = vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf())
  elseif not target:find('functional') then
    target = vim.fs.joinpath(cwd, 'test', 'functional', target)
  end
  if target:match('.*_spec%.lua$') then
    local cmd = ('TEST_FILE=%s make test'):format(target)
    require('run').run(cmd, vim.api.nvim_get_current_buf())
  end
end, {
  nargs = '?',
  complete = 'file',
})
