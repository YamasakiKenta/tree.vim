let s:save_cpo = &cpo
set cpo&vim

function! s:windows_init(title) "{{{
	vertical new
	wincmd H
	vertical resize 20
	if 0
		setlocal buftype=nowrite
		setlocal bufhidden=hide
		setlocal noswapfile
		setlocal nobuflisted
		setlocal nowrap
		setlocal cursorline
		setlocal nofoldenable
	endif
	exe 'setl stl='.a:title
	return bufnr("%")
endfunction
"}}}

function! s:make_tree(datas, func, num)
	let rtns = []
	call add(rtns,  repeat(' ', a:num).'|'.a:num.':- '.a:func)
	for key in keys(a:datas)
		call extend(rtns, s:make_tree(a:datas[key], key, a:num+1))
	endfor
	return rtns
endfunction

function! simple#tree#make(datas)
	" title
	let func = join(keys(a:datas), ',')
	call s:windows_init(func)

	" get lines
	let rtns = []
	for func in keys(a:datas)
		call extend(rtns, s:make_tree(a:datas, func, 1))
	endfor

	" print
	call append(0, rtns)

	" end 
	wincmd p

	return rtns
endfunction

if exists('s:save_cpo')
	let &cpo = s:save_cpo
	unlet s:save_cpo
endif
