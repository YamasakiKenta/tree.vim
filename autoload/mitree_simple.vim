let s:save_cpo = &cpo
set cpo&vim

let s:cahce = {}

function mitree_simple#load(file)
	let lines = readfile(a:file)
	let lines = mitree#util#del_comments(lines)
endfunction

" �֐��Ȃ��肾���ŊǗ�����
let &cpo = s:save_cpo
unlet s:save_cpo
