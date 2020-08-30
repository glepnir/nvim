" Based on vim-json syntax
runtime syntax/json.vim

" Remove syntax group for comments treated as errors
syn clear jsonCommentError

" Define syntax matching comments and their contents
syn keyword jsonCommentTodo  FIXME NOTE TBD TODO XXX
syn match   jsonLineComment  '\/\/.*' contains=@Spell,jsonCommentTodo
syn match   jsonCommentSkip  '^[ \t]*\*\($\|[ \t]\+\)'
syn region  jsonComment      start='/\*'  end='\*/' contains=@Spell,jsonCommentTodo

" Link comment syntax comment to highlighting
hi! def link jsonLineComment    Comment
hi! def link jsonComment        Comment
