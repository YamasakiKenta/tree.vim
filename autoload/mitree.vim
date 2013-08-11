let s:save_cpo = &cpo
set cpo&vim

" {function} : '[{use word}]' "
let s:db = {}
function! mitree#init()
endfunction

" data {{{
" �D��x - ��
let s:pars = { 'c' : [
			\ { 'type' : 'str'  , 'name' : ''                        , 'start' : ';'                       , 'midle' : ''                , 'end' : '.'       } , 
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


let s:pars = { 'c' : [
			\ { 'is_lock' : 1, 'type' : 'str'  , 'func' : function(s:get_name_1) , 'start' : '"'                       , 'midle' : ''                , 'end' : '[^\\]"'  } , 
			\ { 'is_lock' : 0, 'type' : 'if'   , 'func' : function(s:get_name_2) , 'start' : '?'                       , 'midle' : ':'               , 'end' : ';'       } , 
			\ { 'is_lock' : 0, 'type' : 'func' , 'func' : function(s:get_name_3) , 'start' : '{'                       , 'midle' : ''                , 'end' : '}'       } , 
			\ { 'is_lock' : 0, 'type' : 'func' , 'func' : function(s:get_name_4) , 'start' : '('                       , 'midle' : ''                , 'end' : ')'       } , 
			\ { 'is_lock' : 0, 'type' : 'csw'  , 'func' : function(s:get_name_5) , 'start' : '^#ifndef\|^#if\|^#ifdef' , 'midle' : '^#else\|^~#elif' , 'end' : '^#endif' } , 
			\ ]}

let s:kugiri = { 'c' : '[,;]' } 

function s:sget_name_1(line)
	return {
				\ 'name' : 'str',
				\ 'line' : matchstr(a:line, '"\zw.*'),
				\ }
endfunction
function s:sget_name_2(line)
	return {
				\ 'name' : 'no name',
				\ 'line' : matchstr(a:line, '?\zs.*'),
				\ }
endfunction
function s:sget_name_3(line)
	return {
				\ 'name' : matchstr(a:line, '\w\+\ze\s*{'),
				\ 'line' : matchstr(a:line, '{\s*\zs.*'),
				\ }
endfunction
function s:sget_name_4(line)
	return {
				\ 'name' : matchstr(a:line, '\w\+\ze\s*('),
				\ 'line' : matchstr(a:line, '(\s*\zs.*'),
				\ }
endfunction
function s:sget_name_5(line)
	return {
				\ 'name' : matchstr(a:line, '^\(#ifndef\|^#if\|^#ifdef\)\s\+\ze.*'),
				\ 'line' : '',
				\ }
endfunction




" }}}

let :scache_data = {}
" ### 
function! s:sort(a,b)
	return a:a.num < a:b.num
endfunction
function! s:sort_revers(a,b)
	return a:a.num < a:b.num
endfunction

" �ċA�I�ɌĂяo���āA�f�[�^��o�^����
function! s:get_data__sub_get_line_datas(line, hits) "{{{
	" �����ς݂̒T��
	let line_datas = {} " �ۑ��p
	let line       = a:hits.next_line.' '.a:line
	let pars       = s:pars.c

	" �Ώە�������������
	let finds = []
	for par in a:pars
		for type in ['start', 'end']
			let num = match(line, par.[type])
			if num > -1
				let par.type = type
				let par.cnum = num
				call add(finds, par)
			endif
		endfor
	endfor

	 "���ёւ�
	call sort(finds, s:sort)

	" �q�b�g�������ɏ�������
	" TODO: �f�[�^����͂���
	let hits = a:hits
	for find in finds
		if find.type == 'start'
			" �����񒆂͑��̍��ڂ́A��������
			if !exists('hits[0].is_lock') && hits[0].is_lock
				call insert(hits.items, find)
				let tmp_d = call(hits[0].func, [line])
				let par.name = tmp_d.name
				let line     = tmp_d.line
			endif
		elseif find.type == 'end'
			" ���݂̃f�[�^���I������
			if find.end == hits.items[0].end
				unlet hits.items[0]

				"TODO: �f�[�^�x�[�X�ɓo�^���č폜����
			endif
		endif
	endfor

	" �c��̉��

	" TODO: ���񎝉z��, ��͂ł���Ƃ���܂ŉ�͂���
	let hits.next_line = line

	return [line_datas, hits]
endfunction
"}}}

function! s:get_data(line, hits)
	let hits = a:hits
	let hits = s:get_data__sub_get_line_datas(a:line, hits)
	return [hits]
endfunction

function! s:get_datas(lines) "{{{
	" ����
	let hits = {
				\ 'next_line' : '',
				\ 'is_lock' : 0,
				\ 'items' : [],
				\ }
	for line in a:lines
		let [hits] = s:get_data(a:line, hits)
	endfor

	return rtns
endfunction
"}}}

function! s:load(file) "{{{
	let lines = readfile(a:file)

	" �R�����g�̍폜
	let lines = mitree#util#del_comments(lines)

	" ���
	let ana_datas = s:get_datas(lines)

	return ana_datas

endfunction
"}}}

function! mitree#load(files) "{{{
	let files = (type(a:files)==type([])) ? a:files : [a:files]
	let an_datas_all = {}
	for file in files
		let ana_datas = s:load(file)
		let expand(ana_datas_all, ana_datas)
	endfor

	PP ana_datas
endfunction
"}}}

let files = 'C:/Users/kenta/Dropbox/vim/mind/mitree.vim/autoload/test.c'
call mitree#load(files)

let &cpo = s:save_cpo
unlet s:save_cpo
