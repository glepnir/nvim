require('core.pack'):boot_strap()

-- read colorscheme from environment vairable COLORSCHEME
if vim.env.COLORSCHEME then
  vim.cmd.colorscheme(vim.env.COLORSCHEME)
  return
end
