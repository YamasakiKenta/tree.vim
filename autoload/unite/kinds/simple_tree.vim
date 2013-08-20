let s:save_cpo = &cpo
set cpo&vim

function! unite#kinds#simple_tree#define()
	return s:kind
endfunction

let s:kind = {
			\ 'name'           : 'simple_tree',
			\ 'default_action' : 'next',
			\ 'action_table'   : {},
			\ }
let s:kind.action_table.next = {
			\ 'is_selectable' : 0,
			\ 'is_quit' : 0,
			\ }
function! s:kind.action_table.next.func(candidate)
	call unite#start_temporary([['simple_tree/next', a:candidate.action__tagname]]) " # •Â‚¶‚È‚¢ ? 
endfunction

call unite#define_kind(s:kind)

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
