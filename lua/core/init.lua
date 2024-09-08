require('core.pack'):boot_strap()
require('core.options')
vim.cmd.colorscheme('solarized')
local function on_list(options)
  options.title = 'Reference: ' .. vim.fn.expand('<cword>')
  vim.fn.setqflist({}, ' ', options)
  vim.cmd.cfirst()
end

vim.keymap.set('n', '<leader>h', function()
  vim.lsp.buf.references(nil, { on_list = on_list })
end)
