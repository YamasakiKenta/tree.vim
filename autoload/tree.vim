let s:save_cpo = &cpo
set cpo&vim

function! s:sort(a,b)
	return ( a:a.num != a:b.num ) ? ( ( a:a.num > a:b.num ) ? 1 : 0 ) : ( ( a:a.type == 'start' ) ? 0 : 1 ) 
endfunction
" data - pars {{{
function! s:get_name_0(line)
	return {
				\ 'name' : '"',
				\ 'line' : matchstr(a:line, '"\zw.*'),
				\ }
endfunction
function! s:get_name_5(line)
	return {
				\ 'name' : '?',
				\ 'line' : matchstr(a:line, '?\zs.*'),
				\ }
endfunction
function! s:get_name_2(line)
	return {
				\ 'name' : matchstr(a:line, '\w\+\ze\s*{').'{',
				\ 'line' : matchstr(a:line, '{\s*\zs.*'),
				\ }
endfunction
function! s:get_name_3(line)
	return {
				\ 'name' : matchstr(a:line, '\w\+\ze\s*(').'(',
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
			\ { 'is_chain': 0, 'is_lock' : 1 , 'func' : function('s:get_name_0') , 'start' : '\([^\\]\|^\)\zs"'        , 'midle' : ''                , 'end' : '\([^\\]\|^\)\zs"'  } , 
			\ { 'is_chain': 0, 'is_lock' : 0 , 'func' : function('s:get_name_5') , 'start' : '?'                       , 'midle' : ':'               , 'end' : ';'                 } , 
			\ { 'is_chain': 1, 'is_lock' : 0 , 'func' : function('s:get_name_2') , 'start' : '{'                       , 'midle' : ''                , 'end' : '}'                 } , 
			\ { 'is_chain': 0, 'is_lock' : 0 , 'func' : function('s:get_name_3') , 'start' : '('                       , 'midle' : ''                , 'end' : ')'                 } , 
			\ { 'is_chain': 0, 'is_lock' : 0 , 'func' : function('s:get_name_4') , 'start' : '^#ifndef\|^#if\|^#ifdef' , 'midle' : '^#else\|^~#elif' , 'end' : '^#endif'           } , 
			\ ]
" }}}

" 再帰的に呼び出して、データを登録する
function! s:get_datas__sub_get_finds(line) "{{{
	" 対象文字を検索する
	let finds = []
	for par in copy(s:pars)
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
	" TODO: 
	let kugiri = '[,; \t]'
	return split(a:line,  kugiri)
endfunction
"}}}
function! s:get_datas__sub_main(line_data, line, func_name, middle, end, finds) "{{{

	let line      = a:line
	let line_data = a:line_data
	let finds     = a:finds

	let rtns      = []
	let max       = len(line_data.all)

	while max > line_data.lnum
		" 検索したデータを基にリストを作成する
		while len(finds)
			let _find = copy(finds[0])
			unlet finds[0]

			if _find.type == 'start'
				" 文字列中は他の項目は、無視する
				if line_data.is_lock == 0
					" 終了文字と同じ場合はスキップする
					if _find.start != a:end
						let line_data.is_lock = _find.is_lock
						let tmp_dict          = call(_find.func, [line])
						let name              = tmp_dict.name
						let line              = tmp_dict.line

						let [line_data, tmps] = s:get_datas__sub_main(line_data, line, name, _find.midle, _find.end, finds)
						call add(rtns, tmps)
					endif

				endif
			elseif _find.type == 'end'
				if _find.end == a:end
					let line = matchstr(line, '.\{-}\ze'.a:end)
					call extend(rtns, s:get_datas__sub_get_items(line))
					let func_name = len(a:func_name) ? a:func_name : '_'
					return [line_data, { func_name : rtns}]
				endif
			endif
		endwhile

		" 終了条件
		let line_data.lnum = line_data.lnum + 1
		if line_data.lnum >= max
			break
		endif

		" 行の更新
		let line           = line . ' ' . line_data.all[line_data.lnum]
		let finds          = s:get_datas__sub_get_finds(line)
	endwhile


	return [line_data, { a:func_name : rtns}]
endfunction
"}}}
function! s:get_datas(lines) "{{{
	" 検索
	let line_data = {
				\ 'all'     : (type(a:lines)==type([]) ? a:lines : [a:lines]),
				\ 'lnum'    : 0,
				\ 'is_lock' : 0,
				\ }

	" 初期設定
	let line   = line_data.all[line_data.lnum]
	let finds  = s:get_datas__sub_get_finds(line)

	let rtns = s:get_datas__sub_main(line_data, line, '_', '', '', finds)

	return rtns
endfunction
"}}}

function! s:load(file) "{{{
	let lines = readfile(a:file)

	let lines = tree#util#del_comments(lines)

	let rtns = s:get_datas(lines)

	let @" = join(rtns, "\n")

	return rtns
endfunction
"}}}
function! tree#load(files) "{{{
	let files = (type(a:files)==type([])) ? a:files : [a:files]

	for file in files
		call s:load(file)
	endfor

endfunction
"}}}

" let files = 'C:/Users/kenta/Dropbox/vim/mind/tree.vim/autoload/test.c'
" call tree#load(files)

function! s:_test__get_datas__sub_get_finds() "{{{
	call vimwork#test#main(function('s:get_datas__sub_get_finds'), [
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
				\ { 'in' : ['{()(  )()}'], 'out' : [
				\ extend(copy(s:pars[2]), {'type' : 'start', 'num' : 0}),
				\ extend(copy(s:pars[3]), {'type' : 'start', 'num' : 1}),
				\ extend(copy(s:pars[3]), {'type' : 'end',   'num' : 2}),
				\ extend(copy(s:pars[3]), {'type' : 'start', 'num' : 3}),
				\ extend(copy(s:pars[3]), {'type' : 'end',   'num' : 6}),
				\ extend(copy(s:pars[3]), {'type' : 'start', 'num' : 7}),
				\ extend(copy(s:pars[3]), {'type' : 'end',   'num' : 8}),
				\ extend(copy(s:pars[2]), {'type' : 'end',   'num' : 9}),
				\ ]},
				\ { 'in' : ['"  "}'], 'out' : [
				\ extend(copy(s:pars[0]), {'type' : 'start', 'num' : 0}),
				\ extend(copy(s:pars[0]), {'type' : 'end'  , 'num' : 0}),
				\ extend(copy(s:pars[0]), {'type' : 'start', 'num' : 3}),
				\ extend(copy(s:pars[0]), {'type' : 'end',   'num' : 3}),
				\ extend(copy(s:pars[2]), {'type' : 'end',   'num' : 4}),
				\ ]},
				\ ])
endfunction
"}}}

" 最終的には、細かく調査する
function! s:_test__get_datas() "{{{
	call vimwork#test#main(function('s:get_datas'), [
				\ { 'in' : [['void main(void)','{', 'int i;', '}']], 'out' : { 'key' : 1, 
				\ 'main': {
				\ 'args'   : [{ 'type' : 'void', 'name' : ''}],
				\ 'member' : [{ 'type' : 'int', 'name'  : 'i'}],
				\ }}}])
	" endfunction
endfunction
"}}}

" ### TEST ###
" call s:_test__get_datas__sub_get_finds()
call s:_test__get_datas()

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif