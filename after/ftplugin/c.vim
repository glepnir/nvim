let fname = expand('%:p')

if fname =~# '\v(neovim|nvim)'
  setlocal textwidth=120
elseif fname =~# 'vim'
  setlocal listchars=tab:\ \ 
else
  setlocal expandtab
  setlocal shiftwidth=4
  setlocal softtabstop=4
  setlocal tabstop=4
endif

inoreabbrev <buffer> #i #include
