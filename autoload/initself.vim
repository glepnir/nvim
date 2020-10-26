function! initself#clap_go_source()
  let l:go_root = globpath('/usr/local/Cellar/go', '*') . '/libexec/src/'
  let l:go_dicts = split(globpath(l:go_root, '*'))
  let l:result = []
  for item in l:go_dicts
    let l:result = extend(l:result, split(globpath(item, '*.go')))
  endfor
  let l:result_with_cion = []
  for item in l:result
    let icon = clap#icon#get(item)
    call add(l:result_with_cion,icon.' '.item)
  endfor
  let l:gosource={}
  let l:gosource.source = l:result_with_cion
  let l:gosource.sink = function('s:filer_sink')
  let l:gosource.syntax = 'clap_files'
  return l:gosource
endfunction

function! s:filer_sink(selected)
  let l:curline = a:selected[4:]
  execute 'edit' .l:curline
endfunction
