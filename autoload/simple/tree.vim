let s:save_cpo = &cpo
set cpo&vim

function! s:make_tree(datas, func, num)
	let rtns = []
	call add(rtns,  repeat(' ', a:num).'|'.a:num.':- '.a:func)
	for key in keys(a:datas)
		call extend(rtns, s:make_tree(a:datas[key], key, a:num+1))
	endfor
	return rtns
endfunction

function! simple#tree#make(datas)
	let rtns = []
	for func in keys(a:datas)
		call extend(rtns, s:make_tree(a:datas[func], func, 1))
	endfor

	return rtns
endfunction

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
