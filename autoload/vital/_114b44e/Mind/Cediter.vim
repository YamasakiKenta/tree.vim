
let s:save_cpo = &cpo
set cpo&vim

function! s:sort(a,b)
	return ( a:a.cnum > a:b.cnum ) 
endfunction
function! s:_del_comments_sub_hit_no(line, cmnts) "{{{
	let line = a:line
	let hits = []
	let run_flg = 1

	while run_flg == 1 && len(line)
		let run_flg = 0
		" echo a:cmnts
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
function! s:_del_comments_sub_hit(line, cmnts, hits) "{{{
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
		let [line, hits] = s:_del_comments_sub_hit_no(line, a:cmnts)
	endif

	return [line, hits]
endfunction
"}}}
function! s:del_comments(lines,...) "{{{
	if a:0 > 0
		let cmnts = a:1
	else
		let cmnts = [
					\ { 'start' : '\/\/', 'end' : '$'   },
					\ { 'start' : '\/\*', 'end' : '\*\/'}, 
					\ ]
	endif

	let lines   = a:lines
	let hits    = []
	for lnum in range(0, len(lines)-1)
		let line = lines[lnum]
		let [line, hits] = s:_del_comments_sub_hit(line, cmnts, hits)
		let lines[lnum] = line
	endfor
	return lines
endfunction
"}}}

" ### TEST ### {{{
if exists('g:yamaken_test')
	function! s:_func_test(func, in, out) 
		let out = call(a:func, a:in)
		let rtn = ( a:out == out ) 
		if rtn
			echo "OK    :".string(out)
		else
			echo "ERROR :".string(out).' -> '.string(a:out)
		endif
		return rtn
	endfunction

	function! s:_func_tests(func, datas) 
		for data in a:datas
			call s:func_test(a:func, data.in, data.out)
		endfor
	endfunction
	function! s:_test_del_comments() "{{{
		" ,' }, で整形
		"
		let cmnts = [
					\ { 'start' : '\/\/', 'end' : '$'   },
					\ { 'start' : '\/\*', 'end' : '\*\/'}, 
					\ ]

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
					\ { 'in' : [['aaa'], cmnts]                                            ,'out' : ['aaa']            }, 
					\ { 'in' : [['//aaa'], cmnts]                                          ,'out' : ['']               }, 
					\ { 'in' : [['aaa ///*aaa*/bbb'], cmnts]                               ,'out' : ['aaa ']           }, 
					\ ]

		call vimwork#test#main(function('s:del_comments'), datas)
	endfunction
	"}}}

	call s:_test_del_comments()
endif
"}}}

let &cpo = s:save_cpo
unlet s:save_cpo
