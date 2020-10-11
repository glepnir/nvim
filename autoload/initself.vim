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

function! initself#clap_my_dotfiles()
  let l:dotfiles_path = getenv('HOME').'/.dotfiles/'
  let l:dotfiles = filter(split(globpath(l:dotfiles_path, '**'), '\n'), '!isdirectory(v:val)')
  let l:dotfiles += filter(split(globpath(l:dotfiles_path, '.*'), '\n'), '!isdirectory(v:val)')
  let directories = map(glob(fnameescape(l:dotfiles_path).'/{,.}*/', 1, 1), 'fnamemodify(v:val, ":h:t")')
  for dict in directories
    let l:dotfiles += filter(split(globpath(l:dotfiles_path.dict, '.*'), '\n'), '!isdirectory(v:val)')
  endfor
  let l:dotfiles_with_icon = []
  for item in l:dotfiles
    if matchend(item, '/themes/*') >= 0
      call remove(l:dotfiles, index(l:dotfiles,item))
    elseif matchend(item, '/fonts/*')>=0
      call remove(l:dotfiles, index(l:dotfiles,item))
    else
      let icon = clap#icon#get(item)
      call add(l:dotfiles_with_icon,icon.' '.item)
    endif
  endfor
  let l:source_dotfiles ={}
  let l:source_dotfiles.sink = function('s:filer_sink')
  let l:source_dotfiles.source = l:dotfiles_with_icon
  let l:source_dotfiles.syntax = 'clap_files'
  return l:source_dotfiles
endfunction

map <F10> :echo "hi<" . synIDattr(synID(line("."),col("."),1),"name") . '> trans<'
      \ . synIDattr(synID(line("."),col("."),0),"name") . "> lo<"
      \ . synIDattr(synIDtrans(synID(line("."),col("."),1)),"name") . ">"<CR>
