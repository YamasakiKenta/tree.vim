let s:save_cpo = &cpo
set cpo&vim

function! s:get_tree(func)
	let rtn_dict = {}

	echo a:func
	if exists('s:cache[a:func]')
		return { '...' : {} }
	endif

	if !exists('s:dict[a:func]')
		return { 'not define' : {} }
	endif

	for key in keys(s:dict[a:func])
		let rtn_dict[key] = s:get_tree(key)
	endfor

	let s:cache[a:func] = 1

	return rtn_dict
endfunction

function! simple#conv#func_tree(dict, func)
	let s:cache  = {}
	let s:dict   = a:dict

	return s:get_tree(a:func)
endfunction

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
