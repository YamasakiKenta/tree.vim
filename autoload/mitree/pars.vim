let s:save_cpo = &cpo
set cpo&vim

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

	let hit_ends = []
	for hit_num in range(0, len(hits)-1)
		let hit = hits(hit_num)
		if line =~ hit.end
			call add(hit_ends, hit_num)
		endif
	endfor

	call sort(hit_ends)

	if !len(hits)
		let [datas, hits] = s:del_comments_sub_hit_no(line, a:cmnts)
	endif

	return [datas, hits]
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

function! s:get_pars_hits(pars, line, hits)
	" hits �I�������ŕK�v
	" return [hits, datas]
	return s:del_comments_sub_hit(a:line, a:pars, a:hits)
endfunction

function! mitree#del#comments(...)
	return call('s:del_comments', a:000)
endfunction

function! mitree#pars#hits(...)
	return call('s:get_pars_hits', a:000)
endfunction

" ### TEST ###
function! s:test_del_comments() "{{{
	" ,' }, �Ő��`
	"
	let cmnts = { 'c' : [
				\ { 'start' : '"'       , 'midle' : ''      , 'end' : '"'      },
				\ { 'start' : '?'       , 'midle' : ':'     , 'end' : ';'      },
				\ { 'start' : '{'       , 'midle' : ''      , 'end' : '}'      }, 
				\ { 'start' : '('       , 'midle' : ''      , 'end' : ')'      }, 
				\ { 'start' : '#if'     , 'midle' : '#else' , 'end' : '#endif' }, 
				\ { 'start' : '#ifdef'  , 'midle' : '#else' , 'end' : '#endif' }, 
				\ { 'start' : '#ifndef' , 'midle' : '#else' , 'end' : '#endif' }, 
				\ ]}

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

let &cpo = s:save_cpo
unlet s:save_cpo
