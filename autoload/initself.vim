" Credits: https://github.com/Shougo/shougo-s-github/blob/master/vim/rc/options.rc.vim#L147
" mkdir
function! initself#mkdir_as_necessary(dir, force) abort
  if !isdirectory(a:dir) && &l:buftype == '' &&
        \ (a:force || input(printf('"%s" does not exist. Create? [y/N]',
        \              a:dir)) =~? '^y\%[es]$')
    call mkdir(iconv(a:dir, &encoding, &termencoding), 'p')
  endif
endfunction

function! s:lsp_init(langs)
  let l:lsp={
    \'go':{'golang': {
          \ "command": "gopls",
          \ "rootPatterns": ["go.mod"],
          \ "disableWorkspaceFolders": "true",
          \ "filetypes": ["go"]
          \ }
          \ },
    \'dockerfile':{'dockerfile': {
          \ "command": "docker-langserver",
          \ "filetypes": ["dockerfile"],
          \ "args": ["--stdio"]
          \ }
          \ },
    \'sh':{'bash': {
          \ "command": "bash-language-server",
          \ "args": ["start"],
          \ "filetypes": ["sh"],
          \ "ignoredRootPaths": ["~"]
          \ }
          \ }
    \}[a:langs]
  call coc#config('languageserver',l:lsp)
  exec 'autocmd BufWritePre *.'.a:langs. '    call s:silent_organizeImport()'
endfunction

function! s:lsp_command()
  command! -nargs=+ -bar LSP          call s:lsp_init(<args>)
endfunction

call s:lsp_command()

function! s:silent_organizeImport()
  silent! call CocAction('runCommand', 'editor.action.organizeImport')
endfunction

" COC Jump definition in split window
" when window >=4 jump in other window
function! initself#definition_other_window() abort
  if winnr('$') >= 4 || (winwidth(0) - (max([len(line('$')), &numberwidth-1]) + 1)) < 110
    exec "normal \<Plug>(coc-definition)"
  else
    exec 'vsplit'
    exec "normal \<Plug>(coc-definition)"
  endif
endfunction

" COC select the current word
function! initself#select_current_word()
    if !get(g:, 'coc_cursors_activated', 0)
        return "\<Plug>(coc-cursors-word)"
    endif
    return "*\<Plug>(coc-cursors-word):nohlsearch\<CR>"
endfunc

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

" Load Env file and return env content
function! initself#load_env()
  let l:env_file = getenv("HOME")."/.env"
  let l:env_dict={}
  if filereadable(l:env_file)
    let l:env_content = readfile(l:env_file)
    for item in l:env_content
      let l:line_content = split(item,"=")
      let l:env_dict[l:line_content[0]] = l:line_content[1]
    endfor
    return l:env_dict
  else
    echo "env file doesn't exist"
  endif
endfunction

" Load database connection from env file
function! initself#load_db_from_env()
  let l:env = initself#load_env()
  let l:dbs={}
  for key in keys(l:env)
    if stridx(key,"DB_CONNECTION_") >= 0
      let l:db_name = tolower(split(key,"_")[2])
      let l:dbs[l:db_name] = l:env[key]
    endif
  endfor
  if empty(l:dbs)
    echo "Env Database config error"
  endif
  return l:dbs
endfunction

" Remap for do codeAction of selected region
function! initself#coc_action_select(type) abort
    execute 'CocCommand actions.open ' . a:type
endfunction
