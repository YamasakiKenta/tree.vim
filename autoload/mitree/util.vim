let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('mitree.vim')
let s:Cediter = s:V.import('Mind.Cediter')

function! mitree#util#del_comments(...)
	return call(s:Cediter.del_comments, a:000)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
