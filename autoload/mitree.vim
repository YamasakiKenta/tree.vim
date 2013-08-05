let s:save_cpo = &cpo
set cpo&vim

" {function} : '[{use word}]' "
let s:db = {}
function! mitree#init()
endfunction

" �D��x - ��
let s:cmnts = { 'c' : [
			\ { 'start' : '\/\/', 'end' : '$'   },
			\ { 'start' : '\/\*', 'end' : '\*\/'}, 
			\ ]}

let s:pars = { 'c' : [
			\ { 'type' : 'str'  , 'name' : ''                        , 'start' : '"'                       , 'midle' : ''                , 'end' : '"'       } , 
			\ { 'type' : 'if'   , 'name' : ''                        , 'start' : '?'                       , 'midle' : ':'               , 'end' : ';'       } , 
			\ { 'type' : 'func' , 'name' : ''                        , 'start' : '{'                       , 'midle' : ''                , 'end' : '}'       } , 
			\ { 'type' : 'func' , 'name' : '\w\+\ze\s*('             , 'start' : '('                       , 'midle' : ''                , 'end' : ')'       } , 
			\ { 'type' : 'csw'  , 'name' : '^#ifndef\s*\zs.*\ze\s*$' , 'start' : '^#ifndef\|^#if\|^#ifdef' , 'midle' : '^#else\|^~#elif' , 'end' : '^#endif' } , 
			\ ]}

" ������@������
let s:type = { 'c' : {
			\ 'enum'     : [],
			\ 'define'   : [],
			\ 'typedef'  : [],
			\ 'function' : [],
			\ 'static'   : [],
			\ 'var'      : [],
			\ }}

"���̕�������s�Ƃ���
"�����������s��
let s:end_word = { 'c' : [';', '{', '^#.*', ]}


" ### 
function! s:get_data(line, rtns)
	let rtns = a:rtns
	let line = a:line
	let rtns[' '.line] = ''
	return rtns
endfunction

function! s:get_datas(lines, rtns) "{{{
	" ������
	let lines = a:lines
	let indent = 0
	let hit_pars = [] " ���������炯�ɓ˂�����
	let pars = copy(s:pars.c)

	" ����
	let search_word = '\('.join(s:end_word.c, '\|').'\)'
	let amari = ''
	for line in lines
		if line =~ search_word
			let amari = matchstr(line, '\ze'.search_word)
			let rtns = s:get_data(line, a:rtns)
		else
		endif
	endfor

	return rtns
endfunction
"}}}

function! s:load(file, rtns) "{{{
	let lines = readfile(a:file)

	" �R�����g�̍폜
	let lines = mitree#del#comments(s:cmnts.c, lines)

	let rtns = s:get_datas(lines, a:rtns)

	return rtns

endfunction
"}}}

function! mitree#load(files) "{{{
	let files = (type(a:files)==type([])) ? a:files : [a:files]
	let rtns = {}
	for file in files
		let rtns = s:load(file, rtns)
	endfor

	PP rtns
endfunction
"}}}

let files = 'C:/Users/kenta/Dropbox/vim/mind/mitree.vim/autoload/test.c'
call mitree#load(files)

let &cpo = s:save_cpo
unlet s:save_cpo
