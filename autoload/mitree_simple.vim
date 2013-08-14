let s:save_cpo = &cpo
set cpo&vim

let s:cahce = {}

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
			if ifdefs[0].else == 0
				let line = substitute('[{}]', '', 'g')
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
			echo '10 :'.key
			let rtns[key] = 1
		endif
	endfor
	return rtns
endfunction
"}}}
"
function! s:get_datas__sub_func_data(lines, lnum, line, cnt) "{{{
	let cnt     = a:cnt
	let lnum    = a:lnum
	let line    = a:line
	let rtns    = {}
	let end_flg = 0
	let ifdefs  = []

	" 1 ŠÖ”“à‚Ìˆ—
	let max  = len(a:lines)
	while cnt > -1 && lnum < max
		" •¶šƒf[ƒ^‚Ìíœ
		" let line = substitute(line, '".\{-}[^\\]"', '', 'g')

		" ifdef ‚Ìˆ—
		let tmp_dict = s:ifdef_proc(line, ifdefs)
		let line     = tmp_dict.line
		let ifdefs   = tmp_dict.ifdefs

		" I—¹ˆ—‚ğ—Dæ
		let tmp_list = split(' '.line, '}\zs')
		let cnt = cnt - len(tmp_list) + 1
		echo ' === '.lnum. ' === '
		if cnt < 0 
			echo '27 :'. cnt
			let end_flg = 1
			" ŠY“–‚Ì‚©‚Á‚±‚Ü‚Å
			" let m = '\(.\{-}}\)\{'.(-cnt-1).'}.*}'
			" echo m
			" let line = matchstr(line, m)
		endif

		" ŠJnˆ—‚ÌŒvZ
		let cnt = cnt + len(split(line, '{\zs'))

		" ŠÖ”‚Ì’Ç‰Á
		call extend(rtns, s:find_func_name(line))
		let lnum = lnum + 1
		if lnum < max
			let line = a:lines[lnum]
		endif
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

		" ŠÖ”‚ªŒ©‚Â‚©‚Á‚½ê‡
		let tmp_str = matchstr(line, '\w\+\s\+\zs\w\+\ze\s*(')
		if len(tmp_str)
			let func = tmp_str
		endif

		if line =~ '{'
			echo '70 :'. func
			let cnt = len(split(line, '{\zs')) - 1
			echo '77 :'. cnt
			let line = substitute(line, '.\{-}{', '' , 'g')
			let tmp = s:get_datas__sub_func_data(lines, lnum, line, cnt)
			let lnum        = tmp.lnum
			let datas[func] = tmp.func

			" ‘O‰ñ‚Ìƒf[ƒ^‚ğ‚¿‰z‚·
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
function! mitree_simple#load(file) "{{{
	let lines = readfile(a:file)
	let lines = mitree#util#del_comments(lines)
	let rtns = s:get_datas(lines)
	let lines
endfunction
"}}}

" ### TSET ###
function! s:TEST__get_datas() 
	let datas = [
				\ {'in' : [['void main(void) {', 'bbb()', '}']],      'out' : {'main' : {'bbb' : 1}}},
				\ {'in' : [['void main(void) {', 'bbb(ccc())', '}']], 'out' : {'main' : {'bbb' : 1, 'ccc' : 1}}},
				\ {'in' : [['void main(void) {', ' 1 = 1 + ( 1 + 1 )', 'bbb(ccc())', '}']], 'out' : {'main' : {'bbb' : 1, 'ccc' : 1}}},
				\ ]
	call vimwork#test#main(function('s:get_datas'), datas)
endfunction

call s:TEST__get_datas()

" ŠÖ”‚Â‚È‚ª‚è‚¾‚¯‚ÅŠÇ—‚·‚é
if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
