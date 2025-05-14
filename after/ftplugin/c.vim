if expand('%') !~ 'nvim'
  setl expandtab
  setl shiftwidth=4
  setl softtabstop=4
  setl tabstop=4
endif

inoreabbrev <buffer> #i #include
