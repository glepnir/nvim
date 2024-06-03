local name = vim.api.nvim_buf_get_name(0)
--when develop neovim project it use two space
--othewise use 4
local v = name and name:find('neovim') and 2 or 4
vim.opt_local.autoindent = true
vim.opt_local.smartindent = true
vim.opt_local.shiftwidth = v
vim.opt_local.softtabstop = v
vim.opt_local.tabstop = v
vim.opt_local.expandtab = true
