require('core.pack'):boot_strap()
require('core.options')

-- read colorscheme from environment vairable COLORSCHEME
if vim.env.COLORSCHEME then
  vim.cmd.colorscheme(vim.env.COLORSCHEME)
  return
end
