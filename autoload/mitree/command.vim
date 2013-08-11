let s:save_cpo = &cpo
set cpo&vim

function! mitree#command#del_comments() range
	let lines = getline(a:firstline, a:lastline)
	let lines = mitree#util#del_comments(lines)
	call setline(a:firstline, lines)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
