let s:save_cpo = &cpo
set cpo&vim

command! -nargs=? SimpleTreeLoad call simple#data#load("<q-args>", &filetype)

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
