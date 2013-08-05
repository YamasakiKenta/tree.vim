let s:save_cpo = &cpo
set cpo&vim


function! mitree#analyze#get_func_name(lines, lnum, pars)
endfunction

function! s:get_words_from_line(pars, line, hits, words)
	let line = a:line
	let use_words = split(line, '\w\+\zs\W\+')
	let hits = []
	let root = 'main'
	let words = {root : use_words}

	for par in a:pars
		if line =~ par.start
		endif
	endfor

	return [hits, words]
endfunction

function! s:get_words_from_lines(pars, lines)
	let hits = []
	let words = {}
	for line in a:lines
		let [hits, words] = s:get_words_from_line(a:pars, line, hits, words)
	endfor

	echo words
	return words
endfunction

" ### TEST ###
function! s:test() "{{{
	" ,' }, Ç≈êÆå`
	"
let pars = [
			\ { 'type' : 'front', 'word' : '', 'start' : '{'       , 'midle' : ''      , 'end' : '}'      }, 
			\ { 'type' : 'front', 'word' : '', 'start' : '('       , 'midle' : ''      , 'end' : ')'      }, 
			\ { 'type' : 'back',  'word' : '', 'start' : '#if'     , 'midle' : '#else' , 'end' : '#endif' }, 
			\ { 'type' : 'back',  'word' : '', 'start' : '#ifdef'  , 'midle' : '#else' , 'end' : '#endif' }, 
			\ { 'type' : 'back',  'word' : '', 'start' : '#ifndef' , 'midle' : '#else' , 'end' : '#endif' }, 
			\ ]

	let datas = [
				\ { 'in' : [pars, ['aaa()', '{', 'bbb();', '}']]                             ,'out' : {} }, 
				\ ]

	call vimwork#test#main(function('s:get_words_from_lines'), datas)
endfunction
"}}}
if exists('g:mitest')
	call s:test()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
