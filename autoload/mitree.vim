let s:save_cpo = &cpo
set cpo&vim

" {function} : '[{use word}]' "
let s:db = {}
function! mitree#init()
endfunction

" 優先度 - 高
let s:cmnts = { 'c' : [
			\ { 'type' : 'par'  , 'start' : '\/\/', 'midle' : '', 'end' : '$'   },
			\ { 'type' : 'par'  , 'start' : '\/\*', 'midle' : '', 'end' : '\*\/'}, 
			\ ]}

let s:pars = { 'c' : [
			\ { 'start' : '{'       , 'midle' : ''      , 'end' : '}'      }, 
			\ { 'start' : '('       , 'midle' : ''      , 'end' : ')'      }, 
			\ { 'start' : '#if'     , 'midle' : '#else' , 'end' : '#endif' }, 
			\ { 'start' : '#ifdef'  , 'midle' : '#else' , 'end' : '#endif' }, 
			\ { 'start' : '#ifndef' , 'midle' : '#else' , 'end' : '#endif' }, 
			\ ]}

" ### 
" call mitree#del#comments(s:cmnts, lines)
echo mitree#del#comments(s:cmnts, ['aaa'])
function! s:load(lines) "{{{
	let hit_pars = [] " 見つかったらけつに突っ込む
	let indent = 0
	for line in a:lines
		for par in s:pars
			if line =~ s:pars 
			endfor
		endfor
	endfor
endfunction
"}}}

function! mitree#load(files)
	let files = (type(a:files)==type([])) ? a:files : [a:files]
	for file in files
	endfor
endfunction

let files = 'C:/Users/kenta/Dropbox/vim/mind/mitree.vim/autoload/test.c'
call mitree#load(files)

let &cpo = s:save_cpo
unlet s:save_cpo
