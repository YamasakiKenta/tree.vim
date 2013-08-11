let s:save_cpo = &cpo
set cpo&vim

function! s:sort(a,b)
	return ( a:a.num > a:b.num ) ? 1 : 0
endfunction
" data - pars {{{
function! s:get_name_0(line)
	return {
				\ 'name' : 'str',
				\ 'line' : matchstr(a:line, '"\zw.*'),
				\ }
endfunction
function! s:get_name_1(line)
	return {
				\ 'name' : 'no name',
				\ 'line' : matchstr(a:line, '?\zs.*'),
				\ }
endfunction
function! s:get_name_2(line)
	return {
				\ 'name' : matchstr(a:line, '\w\+\ze\s*{'),
				\ 'line' : matchstr(a:line, '{\s*\zs.*'),
				\ }
endfunction
function! s:get_name_3(line)
	return {
				\ 'name' : matchstr(a:line, '\w\+\ze\s*('),
				\ 'line' : matchstr(a:line, '(\s*\zs.*'),
				\ }
endfunction
function! s:get_name_4(line)
	return {
				\ 'name' : matchstr(a:line, '^\(#ifndef\|^#if\|^#ifdef\)\s\+\ze.*'),
				\ 'line' : '',
				\ }
endfunction
let s:pars = [
			\ { 'type' : 'str'  , 'is_lock' : 1 , 'func' : function('s:get_name_0') , 'start' : '"'                       , 'midle' : ''                , 'end' : '[^\\]"'  } , 
			\ { 'type' : 'if'   , 'is_lock' : 0 , 'func' : function('s:get_name_1') , 'start' : '?'                       , 'midle' : ':'               , 'end' : ';'       } , 
			\ { 'type' : 'func' , 'is_lock' : 0 , 'func' : function('s:get_name_2') , 'start' : '{'                       , 'midle' : ''                , 'end' : '}'       } , 
			\ { 'type' : 'func' , 'is_lock' : 0 , 'func' : function('s:get_name_3') , 'start' : '('                       , 'midle' : ''                , 'end' : ')'       } , 
			\ { 'type' : 'csw'  , 'is_lock' : 0 , 'func' : function('s:get_name_4') , 'start' : '^#ifndef\|^#if\|^#ifdef' , 'midle' : '^#else\|^~#elif' , 'end' : '^#endif' } , 
			\ ]
let s:kugiri = '[,;\s]'
" }}}

" 再帰的に呼び出して、データを登録する
function! s:get_datas__sub_get_finds(line) "{{{
	" 対象文字を検索する
	let finds = []
	for par in copy(s:pars)
		" echo par
		for type in ['start', 'end']
			let cnt = 1
			let nums = []
			while(1)
				let num = match(a:line, par[type], 0, cnt)
				if num >= 0
					call add(nums, num)
					let cnt = cnt + 1
				else
					break
				endif
			endwhile

			for num in nums
				let par.type = type
				let par.num = num
				call add(finds, copy(par))
			endfor
		endfor
	endfor

	" ヒットした順に処理したい為、並び替え
	let finds = sort(finds, function('s:sort'))
	return finds
endfunction
"}}}
function! s:get_datas__sub_get_items(line) "{{{
	return split(a:line,  s:kugiri)
endfunction
"}}}
function! s:get_datas__sub_main(line_data, line, func_name, middle, end, finds) "{{{

	let line      = a:line
	let line_data = a:line_data
	let finds     = a:flinds

	let rtns      = { a:func_name : [] }
	let max       = len(line_data.all)

	while max > line_data.lnum
		" 検索したデータを基にリストを作成する
		while len(finds)
			let find = finds[0]
			unlet finds[0]

			if find.type == 'start'
				" 文字列中は他の項目は、無視する
				if line_data.is_lock == 0
					let line_data.is_lock = find.is_lock
					let tmp_dict          = call(find.func, [line])
					let name              = tmp_dict.name
					let line              = tmp_dict.line

					let [line_data, tmps] = get_datas__sub_main(line_data, name, middle, end, finds)
					let add(rtns, tmps)
				endif
			elseif find.type == 'end'
				if find.end == a:end
					let line = matchstr(line, '.\{-}\ze'a:end)
					let extend(rtns[a:func_name], s:get_datas__sub_get_items(line))
					return [line_data, rtns]
				endif
			endif
		endfor

		" 行の更新
		let line_data.lnum = lin_data.lnum + 1
		let line           = line . ' ' . line_data.all[line_data.lnum]
		let finds          = s:get_datas__sub_get_finds(line)
	endfor


	return [line_data, rtns]
endfunction
"}}}
function! s:get_datas(lines) "{{{
	" 検索
	let line_data = {
				\ 'all'     : a:lines,
				\ 'lnum'    : 0,
				\ 'is_lock' : 0,
				\ }

	let line   = line_data.all[line_data.lnum]

	let finds  = s:get_datas__sub_find_par(line)
	
	let line = join(finds, "\n")

	" let rtns = get_datas__sub_main(line_data, line, ' ', '', '', finds)
	"
	let rtns = [line]
	" let rtns = a:lines

	return rtns
endfunction
"}}}

function! s:load(file) "{{{
	let lines = readfile(a:file)

	let lines = mitree#util#del_comments(lines)

	let rtns = s:get_datas(lines)

	let @" = join(rtns, "\n")

	return rtns
endfunction
"}}}
function! mitree#load(files) "{{{
	let files = (type(a:files)==type([])) ? a:files : [a:files]

	for file in files
		call s:load(file)
	endfor

endfunction
"}}}

" let files = 'C:/Users/kenta/Dropbox/vim/mind/mitree.vim/autoload/test.c'
" call mitree#load(files)

function! s:_test()
let datas = [
			\ { 'in' : ['test, test, test'], 'out' : [] } ,
			\ { 'in' : ['()'], 'out' : [
			\ extend(copy(s:pars[3]), {'type' : 'start', 'num' : 0}),
			\ extend(copy(s:pars[3]), {'type' : 'end',   'num' : 1}),
			\ ]},
			\ { 'in' : ['()()()()()'], 'out' : [
			\ extend(copy(s:pars[3]), {'type' : 'start', 'num' : 0}),
			\ extend(copy(s:pars[3]), {'type' : 'end',   'num' : 1}),
			\ extend(copy(s:pars[3]), {'type' : 'start', 'num' : 2}),
			\ extend(copy(s:pars[3]), {'type' : 'end',   'num' : 3}),
			\ extend(copy(s:pars[3]), {'type' : 'start', 'num' : 4}),
			\ extend(copy(s:pars[3]), {'type' : 'end',   'num' : 5}),
			\ extend(copy(s:pars[3]), {'type' : 'start', 'num' : 6}),
			\ extend(copy(s:pars[3]), {'type' : 'end',   'num' : 7}),
			\ extend(copy(s:pars[3]), {'type' : 'start', 'num' : 8}),
			\ extend(copy(s:pars[3]), {'type' : 'end',   'num' : 9}),
			\ ]},
			\ ]

	call vimwork#test#main(function('s:get_datas__sub_get_finds'), datas)
endfunction

call s:_test()

let &cpo = s:save_cpo
unlet s:save_cpo
