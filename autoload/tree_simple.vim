let s:save_cpo = &cpo
set cpo&vim

let s:cache = {}

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
function! s:find_func_name(line) "{{{
	let rtns = {}
	let tmp_list = split(a:line, '(\zs')
	for str in tmp_list
		let key = matchstr(str, '\w\+\ze\s*(')
		if len(key)
			let rtns[key] = 1
		endif
	endfor
	return rtns
endfunction
"}}}
"
function! s:get_datas__sub_func_data(lines, lnum, cnt) "{{{
	let cnt     = a:cnt
	let lnum    = a:lnum
	let rtns    = {}
	let end_flg = 0
	let ifdefs  = []

	" 1 関数内の処理
	let max  = len(a:lines)
	while !end_flg && lnum < max
		let line = a:lines[lnum]
		" 文字データの削除
		let line = substitute(line, '".\{-}[^\\]"', '', 'g')

		" ifdef の処理
		if 0
			let tmp_dict = s:ifdef_proc(line, ifdefs)
			let line     = tmp_dict.line
			let ifdefs   = tmp_dict.ifdefs
		endif

		" 終了処理を優先
		let tmp_list = split(' '.line.' ', '}\zs')
		let cnt = cnt - (len(tmp_list) - 1)
		" echo '65:'.string(tmp_list)
		if cnt < 0 
			let end_flg = 1
			" 該当のかっこまで
			" let m = '\(.\{-}}\)\{'.(-cnt-1).'}.*}'
			" echo m
			" let line = matchstr(line, m)
		endif

		" 開始処理の計算
		let cnt = cnt + (len(split(' '.line, '{\zs')) - 1)

		" 関数の追加
		call extend(rtns, s:find_func_name(line))

		let lnum = lnum + 1
	endwhile

	return {
				\ 'func' : rtns,
				\ 'lnum' : lnum,
				\ 'line' : line,
				\ }
endfunction
"}}}
function! s:get_datas(lines) "{{{
	let datas = {}
	let lnum = 0
	let max = len(a:lines)
	let lines = copy(a:lines)
	while lnum < max
		let line = lines[lnum]

		" 関数が見つかった場合
		let tmp_str = matchstr(line, '\w\+\s\+\zs\w\+\ze\s*(')
		if len(tmp_str)
			let func = tmp_str
		endif

		if line =~ '{'
			let cnt = len(split(line, '{\zs')) - 1
			let lines[lnum] = substitute(line, '.\{-}{', '' , 'g')
			let tmp = s:get_datas__sub_func_data(lines, lnum, cnt)
			let lnum        = tmp.lnum
			let datas[func] = tmp.func

			" 前回のデータを持ち越す
			if lnum < max 
				let lines[lnum] = tmp.line 
			endif
		else
			let lnum = lnum + 1
		endif
	endwhile
	return datas
endfunction
"}}}
"
function! tree_simple#load(file) "{{{
	let files = type(a:file) == type([]) ? a:file : [a:file]
	echo files
	for file in files
		let lines = readfile(file)
		let lines = tree#util#del_comments(lines)
		let rtns = s:get_datas(lines)
		call extend(s:cache, rtns)
	endfor
endfunction
"}}}

" ### TSET ### "{{{
if exists('g:yamaken_test')
function! s:test(func,datas) "{{{
	for data in a:datas
		let ans = data.out
		let out = call(a:func, data.in)
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
	function! s:test__get_datas() "{{{
		let datas = [
					\ {'in' : [['void main(void) {', 'bbb()', '}']],                                           'out' : {'main' : {'bbb' : 1}} },
					\ {'in' : [['void main(void) {', 'bbb(ccc())', '}']],                                      'out' : {'main' : {'bbb' : 1, 'ccc' : 1}} },
					\ {'in' : [['void main(void) {', ' 1 = 1 + ( 1 + 1 )', 'bbb(ccc())', '}']],                'out' : {'main' : {'bbb' : 1, 'ccc' : 1}} },
					\ {'in' : [['void main(void) {', 'printf("printf(%s)", "aaa")', 'bbb(ccc())', '}']],       'out' : {'main' : {'bbb' : 1, 'ccc' : 1, 'printf' : 1, }} },
					\ {'in' : [['void main(void) {', '#if 0', 'bbb(ccc())', '#endif', '}']],                   'out' : {'main' : {'bbb' : 1, 'ccc' : 1}} },
					\ {'in' : [['void main(void) {', '#if 0', 'bbb(ccc())', '#else', 'ddd()', '#endif', '}']], 'out' : {'main' : {'bbb' : 1, 'ccc' : 1, 'ddd' : 1}} },
					\ {'in' : [[
					\ 'void main(void) {', 'if (0) {', 'bbb(ccc());', '}', '}', 
					\ 'static int sum(int a, int b) {', 'MAX(a, b);', 'return a + b;', '}',
					\ ]], 'out' : {'main' : {'bbb' : 1, 'ccc' : 1, 'if' : 1}, 'sum' : {'MAX' : 1}} },
					\ {'in' : [[
					\ 'void main(void) {', '#if 0', 'if (0) {', 'bbb(ccc());', '#else', 'if(1) {', 'ddd();', '#endif', '}', '}', 
					\ 'static int sum(int a, int b) {', 'MAX(a, b);', 'return a + b;', '}',
					\ ]], 'out' : {'main' : {'bbb' : 1, 'ccc' : 1, 'if' : 1, 'ddd' : 1}, 'sum' : {'MAX' : 1}} },
					\ ]
		call s:test(function('s:get_datas'), datas)
	endfunction "}}}
	call s:test__get_datas()
	" call tree_simple#load('ignore.c')
	" echo s:cache
endif
"}}}

" 関数つながりだけで管理する
if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
