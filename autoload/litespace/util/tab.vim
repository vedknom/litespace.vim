" vim: set sw=2 ts=2 sts=2 fdm=indent fml=0:

if exists('g:autoloaded_litespace_util_tab') && g:autoloaded_litespace_util_tab
  finish
endif

let g:autoloaded_litespace_util_tab = 1

function! litespace#util#tab#tempTabNew()
  tabnew
  setlocal buftype=nofile
  setlocal bufhidden=delete
endfunction

