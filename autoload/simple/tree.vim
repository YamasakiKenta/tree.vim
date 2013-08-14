let s:save_cpo = &cpo
set cpo&vim

"### TEST ### "{{{
function! s:make_tree(datas, func_name)
endfunction
"}}}

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
