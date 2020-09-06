" Load Modules:
lua require("core")

  noremap <expr> [d '<cmd>' . v:count1 . 'DiagnosticPrev<CR>'
  noremap <expr> ]d '<cmd>' . v:count1 . 'DiagnosticNext<CR>'
