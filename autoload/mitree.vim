let s:save_cpo = &cpo
set cpo&vim

" {function} : '[{use word}]' "
let s:db = {}
function! mitree#init()
endfunction

" óDêÊìx - çÇ
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

function! s:sort(a,b)
	return ( a:a.cnum > a:b.cnum ) 
endfunction
function! s:del_comments_sub_hit_no(line, cmnts) "{{{
	let line = a:line
	let hits = []
	let run_flg = 1

	while run_flg == 1 && len(line)
		let run_flg = 0
		for cmnt in a:cmnts
			let num = match(line, cmnt.start)
			if num > -1
				let cmnt.cnum = num
				call add(hits, cmnt)
			endif
		endfor

		call sort(hits, 's:sort')

		for hit in hits 
			if match(line, hit.start.'.\{-}'.hit.end) > -1
				let line = substitute(line, hit.start.'.\{-}'.hit.end, '', '')
				let hits = []
				let run_flg = 1
				break
			else
				let line = substitute(line, hit.start.'.*', '', '')
				let hits = [hit]
				break
			endif
		endfor
	endwhile

	return [line, hits]
endfunction
"}}}
function! s:del_comments_sub_hit(line, cmnts, hits) "{{{
	let line = a:line
	let hits = a:hits

	for hit in hits
		if line =~ hit.end
			let line = substitute(line, '.\{-}'.hit.end, "", "")
			let hits = []
		else
			let line = ""
		endif
	endfor

	if !len(hits)
		let [line, hits] = s:del_comments_sub_hit_no(line, a:cmnts)
	endif

	return [line, hits]
endfunction
"}}}
function! s:del_comments(lines) "{{{
	let lines   = a:lines
	let hits    = []
	let type = 'c' " test
	for lnum in range(0, len(lines)-1)
		let line = lines[lnum]
		let cmnts   = copy(s:cmnts[type])
		if !len(hits) 
			let [line, hits] = s:del_comments_sub_hit_no(line, cmnts)
			let lines[lnum] = line
		else
			let [line, hits] = s:del_comments_sub_hit(line, cmnts, hits)
			let lines[lnum] = line
		endif
	endfor
	return lines
endfunction
"}}}

function! s:load(lines) "{{{
	let hit_pars = [] " å©Ç¬Ç©Ç¡ÇΩÇÁÇØÇ¬Ç…ìÀÇ¡çûÇﬁ
	let indent = 0
	for line in a:lines
		for par in s:pars
			if line =~ s:pars 
			endfor
		endfor
	endfor
endfunction
"}}}

function! mitree#load(files) "{{{
	for file in files
	endfor
endfunction
"}}}

" ### TEST ###
function! s:test()
	" ,' }, Ç≈êÆå`
	let datas = [
				\ { 'in' : [['aaa']]                                                   ,'out' : ['aaa']            }, 
				\ { 'in' : [['//aaa']]                                                 ,'out' : ['']               }, 
				\ { 'in' : [['aaa ///*aaa*/bbb']]                                      ,'out' : ['aaa ']           }, 
				\ { 'in' : [['aaa /* ccc */ bbb']]                                     ,'out' : ['aaa  bbb']       }, 
				\ { 'in' : [['aaa /* ccc */ bbb //ccc']]                               ,'out' : ['aaa  bbb ']      }, 
				\ { 'in' : [['aaa /* ccc */ bbb //ccc']]                               ,'out' : ['aaa  bbb ']      }, 
				\ { 'in' : [['//aaa /* ccc */ bbb //ccc']]                             ,'out' : ['']               }, 
				\ { 'in' : [['/*/aaa /* ccc bbb //ccc', 'aaa*/ddd//tset']]             ,'out' : ['', 'ddd' ]       }, 
				\ { 'in' : [['/*/aaa /* ccc bbb //ccc', 'test', 'aaa*/ddd//test']]     ,'out' : ['', '', 'ddd' ]   }, 
				\ { 'in' : [['///*/aaa /* ccc bbb //ccc', 'te/*st', 'aaa*/ddd//test']] ,'out' : ['', 'te', 'ddd' ] }, 
				\ ]
	" let datas = datas[-1:]

	call vimwork#test#main(function('s:del_comments'), datas)
endfunction

if exists('g:mitest')
	call s:test()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
