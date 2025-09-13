setl nocindent
setl expandtab
setl cinkeys-=:

" set indent to 2 when in std header file
if &readonly
  setl sw=2
  setl sts=2
  setl tabstop=2
else
  setl sw=4
  setl sts=4
  setl tabstop=4
endif

