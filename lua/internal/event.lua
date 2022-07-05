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

api.nvim_create_autocmd({'WinEnter','BufEnter','InsertLeave'},{
  group = my_group,
  pattern = '*',
  callback = function()
    if vim.bo.filetype ~= 'dashboard' and not vim.opt_local.cursorline:get() then
      vim.opt_local.cursorline = true
    end
  end
})


api.nvim_create_autocmd({'WinLeave','BufLeave','InsertEnter'},{
  group = my_group,
  pattern = '*',
  callback = function()
    if vim.bo.filetype ~= 'dashboard' and vim.opt_local.cursorline:get() then
      vim.opt_local.cursorline = false
    end
  end
})

api.nvim_create_autocmd({'BufEnter'},{
  group = my_group,
  pattern = '*',
  callback = function()
    if vim.bo.filetype == 'NvimTree' then
      local val = '%#WinbarNvimTreeIcon#   %*'
      local path = vim.fn.getcwd()
      local home = os.getenv("HOME")
      path = path:gsub(home,'~')
      val = val .. '%#WinbarPath#' ..path ..'%*'
      api.nvim_set_hl(0,'WinbarNvimTreeIcon',{fg = '#98be65'})
      api.nvim_set_hl(0,'WinbarPath',{fg = '#fab795'})
      api.nvim_win_set_option(0,'winbar',val)
    end
  end
})

