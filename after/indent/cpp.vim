function! CustomCXXIndent()
  let l:line = getline(v:lnum)
  let l:indent = cindent(v:lnum)
  " i dont' like cindent behavior on namespace
  if l:line =~ '^\s*std:' && l:indent == 0
    return indent(prevnonblank(v:lnum - 1))
  endif
  return l:indent
endfunction

set indentexpr=CustomCXXIndent()
