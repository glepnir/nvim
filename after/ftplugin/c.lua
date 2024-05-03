local name = vim.api.nvim_buf_get_name(0)
--when develop neovim project it use two space
--othewise use 4
local v = name and name:find('neovim') and 2 or 4
vim.opt.commentstring = '//%s'
vim.opt.autoindent = true
vim.opt.smartindent = true
vim.opt.shiftwidth = v
vim.opt.softtabstop = v
vim.opt.tabstop = v
vim.opt.expandtab = true
