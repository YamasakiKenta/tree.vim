let s:save_cpo = &cpo
set cpo&vim

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
function! s:del_comments(cmnts, lines) "{{{
	let lines   = a:lines
	let hits    = []
	for lnum in range(0, len(lines)-1)
		let line = lines[lnum]
		let cmnts   = a:cmnts
			let [line, hits] = s:del_comments_sub_hit(line, cmnts, hits)
			let lines[lnum] = line
	endfor
	return lines
endfunction
"}}}

function! mitree#del#comments(...)
	return call('s:del_comments', a:000)
endfunction

" ### TEST ###
function! s:test_del_comments() "{{{
	" ,' }, Ç≈êÆå`
	"
	let cmnts = [
				\ { 'start' : '\/\/', 'end' : '$'   },
				\ { 'start' : '\/\*', 'end' : '\*\/'}, 
				\ ]

	let datas = [
				\ { 'in' : [cmnts, ['aaa']]                                                   ,'out' : ['aaa']            }, 
				\ { 'in' : [cmnts, ['//aaa']]                                                 ,'out' : ['']               }, 
				\ { 'in' : [cmnts, ['aaa ///*aaa*/bbb']]                                      ,'out' : ['aaa ']           }, 
				\ { 'in' : [cmnts, ['aaa /* ccc */ bbb']]                                     ,'out' : ['aaa  bbb']       }, 
				\ { 'in' : [cmnts, ['aaa /* ccc */ bbb //ccc']]                               ,'out' : ['aaa  bbb ']      }, 
				\ { 'in' : [cmnts, ['aaa /* ccc */ bbb //ccc']]                               ,'out' : ['aaa  bbb ']      }, 
				\ { 'in' : [cmnts, ['//aaa /* ccc */ bbb //ccc']]                             ,'out' : ['']               }, 
				\ { 'in' : [cmnts, ['/*/aaa /* ccc bbb //ccc', 'aaa*/ddd//tset']]             ,'out' : ['', 'ddd' ]       }, 
				\ { 'in' : [cmnts, ['/*/aaa /* ccc bbb //ccc', 'test', 'aaa*/ddd//test']]     ,'out' : ['', '', 'ddd' ]   }, 
				\ { 'in' : [cmnts, ['///*/aaa /* ccc bbb //ccc', 'te/*st', 'aaa*/ddd//test']] ,'out' : ['', 'te', 'ddd' ] }, 
				\ ]
	" let datas = datas[-1:]

	call vimwork#test#main(function('s:del_comments'), datas)
endfunction
"}}}
if exists('g:mitest')
	call s:test_del_comments()
endif

let &cpo = s:save_cpo
unlet s:save_cpo
