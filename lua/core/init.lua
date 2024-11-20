require('core.pack'):boot_strap()
require('core.options')

-- read colorscheme from environment vairable COLORSCHEME
if vim.env.COLORSCHEME then
  vim.cmd.colorscheme(vim.env.COLORSCHEME)
  return
end

if not vim.g.colors_name then
  vim.cmd([[
hi EndOfBuffer guifg=#14161b
hi Function guifg=#a6dbff
hi link @property @variable
hi Type guifg=#fce094
hi link @type.builtin Type
hi link @type Type
hi link Delimiter Comment

hi DiagnosticUnderlineError guisp=#ffc0b9 cterm=undercurl gui=undercurl
hi DiagnosticUnderlineWarn guisp=#fce094 cterm=undercurl gui=undercurl
hi DiagnosticUnderlineInfo guisp=#8cf8f7 cterm=undercurl gui=undercurl
hi DiagnosticUnderlineHint guisp=#a6dbff cterm=undercurl gui=undercurl
hi DiagnosticUnderlineOk guisp=#b3f6c0 cterm=underline gui=underline

hi IndentLine guifg=#2c2e33
hi IndentLineCurrent guifg=#9b9ea4

hi netrwTreeBar guifg=#2c2e33

hi DashboardHeader guifg=#b3f6c0
hi GitSignsAdd guifg=#005523
hi GitSignsChange guifg=#007373
hi GitSignsDelete guifg=#590008
]])
end
