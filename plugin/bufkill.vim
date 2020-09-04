function! s:bdelete(action, bang, buffer_name)
	let buffer = s:str2bufnr(a:buffer_name)
	let w:bbye_back = 1

	if buffer < 0
		return s:error("E516: No buffers were deleted. No match for ".a:buffer_name)
	endif

	if getbufvar(buffer, "&modified") && empty(a:bang)
		let error = "E89: No write since last change for buffer "
		return s:error(error . buffer . " (add ! to override)")
	endif

	" If the buffer is set to delete and it contains changes, we can't switch
	" away from it. Hide it before eventual deleting:
	if getbufvar(buffer, "&modified") && !empty(a:bang)
		call setbufvar(buffer, "&bufhidden", "hide")
	endif

	" For cases where adding buffers causes new windows to appear or hiding some
	" causes windows to disappear and thereby decrement, loop backwards.
	for window in reverse(range(1, winnr("$")))
		" For invalid window numbers, winbufnr returns -1.
		if winbufnr(window) != buffer | continue | endif
		execute window . "wincmd w"

		" Bprevious also wraps around the buffer list, if necessary:
		try | exe bufnr("#") > 0 && buflisted(bufnr("#")) ? "buffer #" : "bprevious"
		catch /^Vim([^)]*):E85:/ " E85: There is no listed buffer
		endtry

		" If found a new buffer for this window, mission accomplished:
		if bufnr("%") != buffer | continue | endif

		call s:new(a:bang)
	endfor

	" Because tabbars and other appearing/disappearing windows change
	" the window numbers, find where we were manually:
	let back = filter(range(1, winnr("$")), "getwinvar(v:val, 'bbye_back')")[0]
	if back | exe back . "wincmd w" | unlet w:bbye_back | endif

	" If it hasn't been already deleted by &bufhidden, end its pains now.
	" Unless it previously was an unnamed buffer and :enew returned it again.
	"
	" Using buflisted() over bufexists() because bufhidden=delete causes the
	" buffer to still _exist_ even though it won't be :bdelete-able.
	if buflisted(buffer) && buffer != bufnr("%")
		exe a:action . a:bang . " " . buffer
	endif
endfunction

function! s:str2bufnr(buffer)
	if empty(a:buffer)
		return bufnr("%")
	elseif a:buffer =~# '^\d\+$'
		return bufnr(str2nr(a:buffer))
	else
		return bufnr(a:buffer)
	endif
endfunction

function! s:new(bang)
	exe "enew" . a:bang

	setl noswapfile
	" If empty and out of sight, delete it right away:
	setl bufhidden=wipe
	" Regular buftype warns people if they have unsaved text there.  Wouldn't
	" want to lose someone's data:
	setl buftype=
	" Hide the buffer from buffer explorers and tabbars:
	setl nobuflisted
endfunction

" Using the built-in :echoerr prints a stacktrace, which isn't that nice.
function! s:error(msg)
	echohl ErrorMsg
	echomsg a:msg
	echohl NONE
	let v:errmsg = a:msg
endfunction

command! -bang -complete=buffer -nargs=? Bdelete
	\ :call s:bdelete("bdelete", <q-bang>, <q-args>)

command! -bang -complete=buffer -nargs=? Bwipeout
	\ :call s:bdelete("bwipeout", <q-bang>, <q-args>)
