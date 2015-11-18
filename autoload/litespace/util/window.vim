" vim: set sw=2 ts=2 sts=2 fdm=indent fml=0:

if exists('g:autoloaded_litespace_util_window') && g:autoloaded_litespace_util_window
  finish
endif

let g:autoloaded_litespace_util_window = 1

function! litespace#util#window#moveTo(winnr)
  let l:windowCount = winnr('$')
  if a:winnr > 0 && a:winnr <= l:windowCount
    let l:currentWinnr = winnr()
    let l:currentWinbufnr = winbufnr(l:currentWinnr)
    if l:currentWinnr != a:winnr
      let l:originalTargetBufnr = winbufnr(a:winnr)
      execute 'buffer ' . l:originalTargetBufnr
      execute a:winnr . 'wincmd w'
      execute 'buffer ' . l:currentWinbufnr
    endif
  endif
endfunction
