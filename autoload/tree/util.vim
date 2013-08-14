let s:save_cpo = &cpo
set cpo&vim

let s:V = vital#of('tree.vim')
let s:Cediter = s:V.import('Mind.Cediter')

function! tree#util#del_comments(...)
	return call(s:Cediter.del_comments, a:000)
endfunction

let &cpo = s:save_cpo
unlet s:save_cpo
