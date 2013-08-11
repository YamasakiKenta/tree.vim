let s:save_cpo = &cpo
set cpo&vim

" {function} : '[{use word}]' "
let s:db = {}
function! mitree#init()
endfunction

" data {{{
" 優先度 - 高
let s:pars = { 'c' : [
			\ { 'type' : 'str'  , 'name' : ''                        , 'start' : ';'                       , 'midle' : ''                , 'end' : '.'       } , 
			\ { 'type' : 'str'  , 'name' : ''                        , 'start' : '"'                       , 'midle' : ''                , 'end' : '"'       } , 
			\ { 'type' : 'if'   , 'name' : ''                        , 'start' : '?'                       , 'midle' : ':'               , 'end' : ';'       } , 
			\ { 'type' : 'func' , 'name' : ''                        , 'start' : '{'                       , 'midle' : ''                , 'end' : '}'       } , 
			\ { 'type' : 'func' , 'name' : '\w\+\ze\s*('             , 'start' : '('                       , 'midle' : ''                , 'end' : ')'       } , 
			\ { 'type' : 'csw'  , 'name' : '^#ifndef\s*\zs.*\ze\s*$' , 'start' : '^#ifndef\|^#if\|^#ifdef' , 'midle' : '^#else\|^~#elif' , 'end' : '^#endif' } , 
			\ ]}

" 判定方法を入れる
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

" 再帰的に呼び出して、データを登録する
function! s:get_data__sub_get_line_datas(line, hits) "{{{
	" 検索済みの探索
	let line_datas = {} " 保存用
	let line       = a:hits.next_line.' '.a:line
	let pars       = s:pars.c

	" 対象文字を検索する
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

	 "並び替え
	call sort(finds, s:sort)

	" ヒットした順に処理する
	" TODO: データを解析する
	let hits = a:hits
	for find in finds
		if find.type == 'start'
			" 文字列中は他の項目は、無視する
			if !exists('hits[0].is_lock') && hits[0].is_lock
				call insert(hits.items, find)
				let tmp_d = call(hits[0].func, [line])
				let par.name = tmp_d.name
				let line     = tmp_d.line
			endif
		elseif find.type == 'end'
			" 現在のデータを終了する
			if find.end == hits.items[0].end
				unlet hits.items[0]

				"TODO: データベースに登録して削除する
			endif
		endif
	endfor

	" 残りの解析

	" TODO: 次回持越し, 解析できるところまで解析する
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
	" 検索
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

	" コメントの削除
	let lines = mitree#util#del_comments(lines)

	" 解析
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
