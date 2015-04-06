" litespace.vim - Lightweight workspace manager
" Maintainer:   Ved Knom
" Version:      0.1

if (exists("g:loaded_litespace") && g:loaded_litespace) || &cp || v:version < 700
    finish
endif
let g:loaded_litespace = 1

function! s:MoveToWindow(windowNR)
  let windowCount = winnr('$')
  if a:windowNR > 0 && a:windowNR <= windowCount
    let currentWindowNR = winnr()
    let currentWindowBufferNR = winbufnr(currentWindowNR)
    if currentWindowNR != a:windowNR
      let originalTargetBufferNR = winbufnr(a:windowNR)
      execute 'buffer ' . originalTargetBufferNR
      execute a:windowNR . 'wincmd w'
      execute 'buffer ' . currentWindowBufferNR
    endif
  endif
endfunction

function! s:DebugBufferEvent(type)
  echom 'type: ' . a:type
    \ . ', afile: "' . expand('<afile>') . '"'
    \ . ', #: ' . expand('<abuf>')
endfunction

augroup LiteSpace
  autocmd!
  autocmd BufWinEnter * call <SID>DebugBufferEvent('winenter')
  autocmd BufUnload * call <SID>DebugBufferEvent('unload')
augroup END

nnoremap <unique> <Leader>tn :tabnew<CR>
nnoremap <unique> <Leader>wm1 :call <SID>MoveToWindow(1)<CR>
nnoremap <unique> <Leader>wm2 :call <SID>MoveToWindow(2)<CR>
nnoremap <unique> <Leader>wm3 :call <SID>MoveToWindow(3)<CR>
nnoremap <unique> <Leader>wm4 :call <SID>MoveToWindow(4)<CR>
nnoremap <unique> <Leader>wnt :tab split<CR>:rightbelow vnew<CR>:wincmd w<CR>
