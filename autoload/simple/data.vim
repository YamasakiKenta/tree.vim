set cpo&vim

let s:cache_next = {}
let s:cache_back = {}
let s:cache_file = {}

function! s:ifdef_proc(line, ifdefs) "{{{
	let ifdefs = a:ifdefs
	let line   = a:line

	if line =~ '^#if'
		call insert(ifdefs, {'else' : 0})
	elseif line =~ '#else'
		let ifdefs[0].else = 1
	elseif line =~ '#endif'
		unlet  ifdefs[0]
	else
		if len(ifdefs)
			if ifdefs[0].else == 1
				let line = substitute(line, '[{}]', '', 'g')
			endif
		endif
	endif

	return {
				\'line'   : line,
				\'ifdefs' : ifdefs,
				\ }
endfunction
"}}}

let s:func_types = {
	\ 'c' : {
	\ 'def_func_name'       : '\w\+\s\+\zs\w\+\ze\s*(',
	\ 'use_func_name'       : '\w\+\ze\s*(',
	\ 'use_func_name_split' : '(\zs',
	\ 'moji'                : '".\{-}[^\\]"',
	\ 'start'               : '{',
	\ 'end'                 : '}',
	\'cmnts' : [
	\ { 'start' : '\/\/', 'end' : '$'   },
	\ { 'start' : '\/\*', 'end' : '\*\/'}, 
	\ ],
	\ },
	\ 'vim' : {
	\ 'def_func_name'       : '\<fu\%[nction]!\?\s\+\zs[a-zA-Z:#_]\+\ze(',
	\ 'use_func_name'       : '\<[a-zA-Z:#_]\+\ze\s*(',
	\ 'use_func_name_split' : '(\zs',
	\ 'moji'                : '',
	\ 'start'               : ')',
	\ 'end'                 : '\<endf\%[unction]!\?\>',
	\'cmnts' : [
	\ ],
	\ }}

function! s:find_func_name(line, func_type) "{{{
	let rtns = {}
	let tmp_list = split(a:line, a:func_type.use_func_name_split)
	for str in tmp_list
		let key = matchstr(str, a:func_type.use_func_name)
		if len(key)
			let rtns[key] = 1
		endif
	endfor
	return rtns
endfunction
"}}}

function! s:get_datas__sub_func_data(lines, lnum, cnt, func_type) "{{{
	let cnt     = a:cnt
	let lnum    = a:lnum
	let rtns    = {}
	let end_flg = 0
	let ifdefs  = []

	" 1 関数内の処理
	let max  = len(a:lines)
	let end = a:func_type.end
	let start = a:func_type.start
	while !end_flg && lnum < max
		let line = a:lines[lnum]
		" 文字データの削除
		let line = substitute(line, a:func_type.moji, '', 'g')

		" ifdef の処理
		if 0
			let tmp_dict = s:ifdef_proc(line, ifdefs)
			let line     = tmp_dict.line
			let ifdefs   = tmp_dict.ifdefs
		endif

		" 終了処理を優先
		let tmp_list = split(' '.line.' ', end.'\zs')
		let cnt = cnt - (len(tmp_list) - 1)
		if cnt < 0 
			let end_flg = 1
			" TODO: 該当のかっこまで
		endif

		" 開始処理の計算
		let cnt = cnt + (len(split(' '.line, start.'\zs')) - 1)

		" 関数の追加
		call extend(rtns, s:find_func_name(line, a:func_type))

		let lnum = lnum + 1
	endwhile

	return {
				\ 'fnc'  : rtns,
				\ 'lnum' : lnum,
				\ 'line' : line,
				\ }
endfunction
"}}}

function! s:get_datas(func_type, lines) "{{{
	let data_next = {}
	let data_back = {}
	let lnum  = 0
	let max   = len(a:lines)
	let lines = copy(a:lines)

	let word_name = a:func_type.def_func_name
	let end       = a:func_type.end
	let start     = a:func_type.start
	while lnum < max
		let line = lines[lnum]

		" 関数が見つかった場合
		let tmp_str = matchstr(line, word_name)
		if len(tmp_str)
			let fnc = tmp_str
		endif

		if line =~ start
			let cnt         = len(split(line, '{\zs')) - 1
			" 関数名を削除する
			let lines[lnum] = substitute(line, '.\{-}'.start, '' , 'g')
			let tmp         = s:get_datas__sub_func_data(lines, lnum, cnt, a:func_type)
			let lnum        = tmp.lnum

			" 遷移先を保存する
			let data_next[fnc] = tmp.fnc

			" 戻り先を保存する
			for next_func in keys(tmp.fnc)
				if !exists('data_back[next_func]')
					let data_back[next_func] = {}
				endif
				let data_back[next_func][fnc] = 1
			endfor

			" 前回のデータを持ち越す
			if lnum < max 
				let lines[lnum] = tmp.line 
			endif
		else
			let lnum = lnum + 1
		endif
	endwhile
	return {
				\ 'next' : data_next,
				\ 'back' : data_back,
				\ }
endfunction
"}}}

function! simple#data#load(file, ft) "{{{
	let files = type(a:file) == type([]) ? a:file : [a:file]

	if !exists('s:func_types[a:ft]')
		echo 'not support '.a:ft
		return []
	endif

	let cmnts = s:func_types[a:ft].cmnts

	for file in files
		let lines = readfile(file)
		let lines = tree#util#del_comments(lines, cmnts)

		let data  = s:get_datas(s:func_types[a:ft], lines)

		" ファイル内の関数
		echo data

		let s:cache_file[fnamemodify(a:file,"p")] = keys(data.next) " com

		" 全体に登録
		call extend(s:cache_next, data.next)
	endfor

	return s:cache_file[fnamemodify(a:file,"p")]
endfunction
"}}}

function! simple#data#next(fnc)
	return simple#conv#func_tree(s:cache_next, a:fnc)
endfunction

function! simple#data#back(fnc)
	return simple#conv#func_tree(s:cache_back, a:fnc)
endfunction

function! simple#data#func()
	return keys(deepcopy(s:cache_next))
endfunction

" ### TSET ### "{{{
if exists('g:yamaken_test') 
	function! s:test(fnc,datas) "{{{
		for data in a:datas
			let ans = data.out
			let out = call(a:fnc, data.in)
			if exists('data.key')
				let out = get(out, data.key, '')
			endif
			if type(data.out) == type(out) && ( data.out == out ) 
				echo "OK     :" . string(out)
			else
				echo "ERROR  :"
				echo '= ans =:'.string(data.out)
				echo '= rtn =:'.string(out)
			endif
		endfor
	endfunction
	"}}}
	if 1
		" s:get_datas "{{{
		call s:test(function('s:get_datas'), [ 
					\ {'key' : 'next', 'in' : [s:func_types.c, ['void main(void) {', 'bbb()', '}']],                                           'out' : {'main' : {'bbb' : 1}} },
					\ {'key' : 'next', 'in' : [s:func_types.c, ['void main(void) {', 'bbb(ccc())', '}']],                                      'out' : {'main' : {'bbb' : 1, 'ccc' : 1}} },
					\ {'key' : 'next', 'in' : [s:func_types.c, ['void main(void) {', ' 1 = 1 + ( 1 + 1 )', 'bbb(ccc())', '}']],                'out' : {'main' : {'bbb' : 1, 'ccc' : 1}} },
					\ {'key' : 'next', 'in' : [s:func_types.c, ['void main(void) {', 'printf("printf(%s)", "aaa")', 'bbb(ccc())', '}']],       'out' : {'main' : {'bbb' : 1, 'ccc' : 1, 'printf' : 1, }} },
					\ {'key' : 'next', 'in' : [s:func_types.c, ['void main(void) {', '#if 0', 'bbb(ccc())', '#endif', '}']],                   'out' : {'main' : {'bbb' : 1, 'ccc' : 1}} },
					\ {'key' : 'next', 'in' : [s:func_types.c, ['void main(void) {', '#if 0', 'bbb(ccc())', '#else', 'ddd()', '#endif', '}']], 'out' : {'main' : {'bbb' : 1, 'ccc' : 1, 'ddd' : 1}} },
					\ {'key' : 'next', 'in' : [s:func_types.c, [
					\ 'void main(void) {', 'if (0) {', 'bbb(ccc());', '}', '}', 
					\ 'static int sum(int a, int b) {', 'MAX(a, b);', 'return a + b;', '}',
					\ ]], 'out' : {'main' : {'bbb' : 1, 'ccc' : 1, 'if' : 1}, 'sum' : {'MAX' : 1}} },
					\
					\ {'key' : 'next', 'in' : [s:func_types.c, [
					\ 'void main(void) {', '#if 0', 'if (0) {', 'bbb(ccc());', '#else', 'if(1) {', 'ddd();', '#endif', '}', '}', 
					\ 'static int sum(int a, int b) {', 'MAX(a, b);', 'return a + b;', '}',
					\ ]], 'out' : {'main' : {'bbb' : 1, 'ccc' : 1, 'if' : 1, 'ddd' : 1}, 'sum' : {'MAX' : 1}} },
					\
					\ {'key' : 'next', 'in' : [s:func_types.vim, ['function! s:main()', 'call s:bbb()', 'endfunction']], 'out' : {'s:main' : {'s:bbb' : 1}} },
					\ {'key' : 'next', 'in' : [s:func_types.vim, ['function! main#aaa#bbb(a,b,c)', 'call s:bbb()', 'return aaa#bbb()', 'endfunction']], 'out' : {'main#aaa#bbb' : {'s:bbb' : 1, 'aaa#bbb' : 1}} },
					\ ])
		"}}}
	endif

	" let fname = "C:/Users/kenta/Dropbox/vim/mind/tree.vim/autoload/test/test.c"
	" call simple#data#load(fname, 'c')

	" let fname = 'C:/Users/kenta/Dropbox/vim/mind/tree.vim/autoload/unite/sources/simple_tree.vim'
	" call simple#data#load(fname, 'vim')
endif
"}}}
"

" 関数つながりだけで管理する
if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
