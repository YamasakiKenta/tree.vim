let s:save_cpo = &cpo
set cpo&vim

function! unite#kinds#simple_tree#define()
	return s:kind
endfunction

let s:kind = {
			\ 'name'           : 'simple_tree',
			\ 'defualt_action' : 'next',
			\ 'action_table'   : {},
			\ }
let s:kind.action_table.next = {}
function! s:kind.action_table.next.func(candidates)
	call unite#start('simple_tree/next', candidates.action__func_name)
endfunction

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
