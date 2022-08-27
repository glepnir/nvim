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

vim.api.nvim_create_autocmd('BufWritePre', {
  group = my_group,
  pattern = '*.go',
  callback = function()
    if not packer_plugins['lspconfig'] then
      return
    end
    local params = vim.lsp.util.make_range_params(nil, vim.lsp.util._get_offset_encoding())
    params.context = { only = { 'source.organizeImports' } }

    local result = vim.lsp.buf_request_sync(0, 'textDocument/codeAction', params, 3000)
    for _, res in pairs(result or {}) do
      for _, r in pairs(res.result or {}) do
        if r.edit then
          vim.lsp.util.apply_workspace_edit(r.edit, vim.lsp.util._get_offset_encoding())
        else
          vim.lsp.buf.execute_command(r.command)
        end
      end
    end
  end,
})

api.nvim_create_autocmd('BufWritePost', {
  group = my_group,
  pattern = '*.go',
  callback = function()
    if vim.bo.filetype == 'lua' then
      if vim.fn.expand('%:t'):find('%pspec') then
        return
      end
    end
    require('internal.formatter'):formatter()
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

api.nvim_create_autocmd({ 'BufEnter' }, {
  group = my_group,
  pattern = '*',
  callback = function()
    if vim.bo.filetype == 'NvimTree' then
      local val = '%#WinbarNvimTreeIcon#   %*'
      local path = vim.fn.getcwd()
      local home = os.getenv('HOME')
      path = path:gsub(home, '~')
      val = val .. '%#WinbarPath#' .. path .. '%*'
      api.nvim_set_hl(0, 'WinbarNvimTreeIcon', { fg = '#98be65' })
      api.nvim_set_hl(0, 'WinbarPath', { fg = '#fab795' })
      api.nvim_win_set_option(0, 'winbar', val)
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
