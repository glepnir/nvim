" From https://github.com/tpope/tpope/blob/master/.vimrc
setlocal includeexpr=substitute(v:fname,'\\.','/','g').'.lua'
setlocal comments-=:-- comments+=:---,:--

inoreabbrev <buffer> lo local
inoreabbrev <buffer> lf local function()<left><left>
inoreabbrev <buffer> fu function() end<left><left><left><left>

function! s:RunFunctionalTestOnCtrlG() abort
  let l:fullpath = expand('%:p')

  if l:fullpath !~# '/neovim/test/functional/'
    return "\<C-G>"
  endif

  let l:file = substitute(l:fullpath, '.*/\(test/functional/.*\)', '\1', '')
  let l:cmd = 'TEST_FILE=' . l:file . ' make test'

  call setreg('+', l:cmd)

  return "\<C-G>"
endfunction

nnoremap <expr> <C-G> <SID>RunFunctionalTestOnCtrlG()
