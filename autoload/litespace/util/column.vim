" vim: set sw=2 ts=2 sts=2 fdm=indent fml=0:

if exists('g:autoloaded_litespace_util_column') && g:autoloaded_litespace_util_column
  finish
endif

let g:autoloaded_litespace_util_column = 1

" Constants
let s:temp_marker = 'litespace_keep_window_temp_marker'

" Helper
function! s:CloseWindows(movement)
  while 1
    let l:prevWinnr = winnr()
    execute 'wincmd ' . a:movement
    if winnr() == l:prevWinnr
      break
    endif
  endwhile
  while 1
    if getwinvar(winnr(), s:temp_marker, 0)
      break
    endif
    wincmd c
  endwhile
endfunction

function! s:WindowBufnrs()
  let l:winbufnrs = [-1]
  let l:windowCount = winnr('$')
  let l:windowIndex = 1
  while l:windowIndex <= l:windowCount
    call add(l:winbufnrs, winbufnr(l:windowIndex))
    let l:windowIndex += 1
  endwhile
  return l:winbufnrs
endfunction

function! s:ColumnPrimaryWindowWith(primary, other)
  let l:primary = a:primary
  let l:other = a:other
  let l:curwinnr = winnr()
  let l:winbufnrs = s:WindowBufnrs()
  call remove(l:winbufnrs, l:curwinnr)
  " echom join(l:winbufnrs)
  wincmd o
  let l:restoreWinnr = winnr()
  let l:windowIndex = 1
  while l:windowIndex < len(l:winbufnrs)
    let l:bufnr = l:winbufnrs[l:windowIndex]
    if l:bufnr != -1
      if l:windowIndex == 1
        execute l:primary
      else
        execute l:other
      endif
      wincmd =
      execute 'buffer ' . l:bufnr
      let l:windowIndex += 1
    endif
  endwhile
  execute l:restoreWinnr . 'wincmd w'
endfunction

" API
function! litespace#util#column#only()
  let l:winnr = winnr()
  call setwinvar(l:winnr, s:temp_marker, 1)
  call s:CloseWindows('k')
  call s:CloseWindows('j')
  execute 'unlet w:' . s:temp_marker
endfunction

function! litespace#util#column#primaryHorizontal()
  call s:ColumnPrimaryWindowWith('rightbelow new', 'leftabove vnew')
endfunction

function! litespace#util#column#primaryVertical()
  call s:ColumnPrimaryWindowWith('rightbelow vnew', 'leftabove new')
endfunction
