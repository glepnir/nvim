" From https://github.com/tpope/tpope/blob/master/.vimrc
setlocal includeexpr=substitute(v:fname,'\\.','/','g').'.lua'
setlocal comments-=:-- comments+=:---,:--

inoreabbrev <buffer> lo local
inoreabbrev <buffer> lf local function()<left><left>
inoreabbrev <buffer> fu function() end<left><left><left><left>
inoreabbrev <buffer> fo (''):format()<left><left><s-left><left><left><left>
