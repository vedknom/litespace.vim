" litespace.vim - Lightweight workspace manager
" Maintainer:   Ved Knom
" Version:      0.1

if (exists("g:loaded_litespace") && g:loaded_litespace) || &cp || v:version < 700
    finish
endif
let g:loaded_litespace = 1

let g:buffer_list_height = 10

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
    \ . ', tab: ' . tabpagenr()
endfunction

function! s:GetTabBufferList()
    let tabNR = tabpagenr()
    let bufferList = gettabvar(tabNR, 'litespace_buffer_list', {})
    if empty(bufferList)
        call settabvar(tabNR, 'litespace_buffer_list', bufferList)
    endif
    return bufferList
endfunction

function! s:AddBuffer()
    let bufNR = expand('<abuf>')
    let bufferList = s:GetTabBufferList()
    let bufferList[bufNR] = bufNR
endfunction

function! s:RemoveBuffer(bufferNR)
    let bufferList = s:GetTabBufferList()
    if has_key(bufferList, a:bufferNR)
        unlet bufferList[a:bufferNR]
    endif
endfunction

function! s:RemoveListBuffersWindow(bufferNR)
    execute 'silent! bunload ' . a:bufferNR
    execute 'silent! bdelete ' . a:bufferNR
endfunction

function! s:ListBuffers()
    let currentWindowNR = winnr()
    let currentWindowBufferNR = winbufnr(currentWindowNR)
    let bufferList = s:GetTabBufferList()
    if empty(bufferList)
        echom 'Tab buffer list is empty'
    else
        let bufferNames = []
        for key in sort(keys(bufferList))
            let bufferNR = str2nr(key)
            if bufferNR != currentWindowBufferNR
                if !bufexists(bufferNR)
                    echoerr 'Stale buffer was not removed from list ' . bufferNR
                else
                    let bufferRawName = bufname(bufferNR)
                    let bufferName = empty(bufferRawName) ? '[No Name]' : bufferRawName
                    let bufferLine = key . "\t" . bufferName
                    call add(bufferNames, bufferLine)
                endif
            endif
        endfor

        if empty(bufferNames)
            echom 'Tab buffer list is empty'
        else
            rightbelow new
            wincmd J
            let buffer_list_height = min([g:buffer_list_height, len(bufferNames)])
            execute buffer_list_height . 'wincmd _'

            set modifiable
            call append(0, bufferNames)
            normal ddgg
            let bufferListNR = bufnr('%')
            call s:RemoveBuffer(bufferListNR)

            autocmd BufLeave <buffer> call <SID>RemoveListBuffersWindow(expand('<abuf>'))
            autocmd BufWinLeave <buffer> call <SID>RemoveListBuffersWindow(expand('<abuf>'))
            nnoremap <buffer> <C-c> :call <SID>RemoveListBuffersWindow(bufnr('%'))<CR>

            set buftype=nofile
            set nomodifiable
        endif
    endif
endfunction

augroup LiteSpace
  autocmd!
  autocmd BufEnter * call <SID>AddBuffer()
  autocmd BufWinEnter * call <SID>AddBuffer()
  autocmd BufUnload * call <SID>RemoveBuffer(expand('<abuf>'))
augroup END

nnoremap <unique> <Leader>tn    :tabnew<CR>
nnoremap <unique> <Leader>wm1   :call <SID>MoveToWindow(1)<CR>
nnoremap <unique> <Leader>wm2   :call <SID>MoveToWindow(2)<CR>
nnoremap <unique> <Leader>wm3   :call <SID>MoveToWindow(3)<CR>
nnoremap <unique> <Leader>wm4   :call <SID>MoveToWindow(4)<CR>
nnoremap <unique> <Leader>wnt   :tab split<CR>:rightbelow vnew<CR>:wincmd w<CR>
nnoremap <unique> <Leader>ls    :call <SID>ListBuffers()<CR>
