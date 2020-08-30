setlocal indentexpr=scss_indent#GetIndent(v:lnum)

" Automatically insert the current comment leader after hitting <Enter>
" in Insert mode respectively after hitting 'o' or 'O' in Normal mode
setlocal formatoptions+=ro

" SCSS comments are either /* */ or //
setlocal comments=s1:/*,mb:*,ex:*/,://

set iskeyword+=-
