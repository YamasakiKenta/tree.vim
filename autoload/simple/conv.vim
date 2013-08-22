let s:save_cpo = &cpo
set cpo&vim

function! s:get_tree(func)
	let rtn_dict = {}

	if !exists('s:dict[a:func]')
		return { '???' : {} }
	endif

	if exists('s:cache[a:func]') 
		return { '...' : {} }
	else
		let s:cache[a:func] = 'start'
	endif

	for key in keys(s:dict[a:func])
		let rtn_dict[key] = s:get_tree(key)
	endfor

	let s:cache[a:func] = 'end'

	return rtn_dict
endfunction

function! simple#conv#func(dict, func)
	let s:cache = {}
	let s:dict  = a:dict
	let rtns    = s:get_tree(a:func)
	return rtns
endfunction

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
