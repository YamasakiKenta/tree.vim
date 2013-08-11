let s:save_cpo = &cpo
set cpo&vim

command! -range MiDelComment <line1>,<line2>call mitree#command#del_comments()

let &cpo = s:save_cpo
unlet s:save_cpo
