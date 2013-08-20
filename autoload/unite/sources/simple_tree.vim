let s:save_cpo = &cpo
set cpo&vim

function! unite#sources#simple_tree#define()
	return s:sources
endfunction

let s:sources = []
let s:source = {
			\ 'name'         : 'simple_tree',
			\ 'default_kind' : 'simple_tree',
			\ 'hooks' : {},
			\ }
function! s:source.hooks.on_init(args, context) "{{{
	" TODO: データの更新をタイムスタンプで管理する
	if len(a:args)
		let a:context.source__file_name = a:arg[0]
		let a:context.source__file_type = a:arg[1]
	else
		let a:context.source__file_name = input("file name: ", expand("%:p"))
		let a:context.source__file_type = input("file type: ", &filetype)
	endif
endfunction
"}}}
function! s:source.gather_candidates(args, context) "{{{
	if !exists('a:context.source__file_type') || !exists('a:context.source__file_name')
		return {}
	endif

	let ft    = a:context.source__file_type
	let fname = a:context.source__file_name
	let datas = simple#data#load(fname, ft)

	return map(datas, '{
				\ "word" : v:val,
				\ "action__tagname" : v:val,
				\ }')
endfunction
"}}}
call add(s:sources, deepcopy(s:source))

let s:source = {
			\ 'name'         : 'simple_tree/next',
			\ 'default_kind' : 'jump_list',
			\ 'hooks' : {},
			\ }
function! s:conv_func_from_simple_tree(str) "{{{
	" ファイル名の抽出
	return matchstr(a:str, '-|\d*:\zs\S*')
endfunction
"}}}
function! s:source.hooks.on_init(args, context) "{{{
	" TODO: データの更新をタイムスタンプで管理する
	if len(a:args)
		let a:context.source__func_name = a:args[0]
	else
		let a:context.source__func_name = input("func name: ")
	endif
endfunction
"}}}
function! s:source.gather_candidates(args, context) "{{{
	let dict = simple#data#next(a:context.source__func_name)
	echo dict
	let datas = simple#tree#make(dict)

	return map(datas, '{
				\ "word" : v:val,
				\ "action__tagname" : s:conv_func_from_simple_tree(v:val),
				\ }')
endfunction
"}}}
call add(s:sources, deepcopy(s:source))

call unite#define_source(s:sources)

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
