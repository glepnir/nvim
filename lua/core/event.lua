local api = vim.api
local my_group = vim.api.nvim_create_augroup('GlepnirGroup',{})

api.nvim_create_autocmd({'BufWritePre'},{
  group = my_group,
  pattern =  {'/tmp/*','COMMIT_EDITMSG','MERGE_MSG','*.tmp','*.bak'},
  callback = function()
    vim.opt_local.undofile = false
  end
})

api.nvim_create_autocmd('TextYankPost',{
  group = my_group,
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({higroup="IncSearch", timeout=400})
  end
})

api.nvim_create_autocmd('BufWritePre',{
  group = my_group,
  pattern = '*.go',
  callback = function()
    require('internal.golines').golines_format()
  end
})
