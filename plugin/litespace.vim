" litespace.vim - Lightweight workspace manager
" Maintainer:   Ved Knom
" Version:      0.1

if (exists("g:loaded_litespace") && g:loaded_litespace) || &cp || v:version < 700
    finish
endif
let g:loaded_litespace = 1

" let g:litespace_buffer_list_height = 10
" let g:litespace_show_unnamed = 0

" Window manipulation
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

function! s:CloseWindowsAbove()
    while 1
        let preWindowNR = winnr()
        wincmd k
        let postWindowNR = winnr()
        if preWindowNR == postWindowNR
            break
        endif
        wincmd c
    endwhile
endfunction

function! s:CloseWindowsBelow()
    let windowNR = winnr()
    wincmd j
    while winnr() != windowNR
        wincmd c
    endwhile
endfunction

function! s:ColumnOnlyWindow()
    call s:CloseWindowsAbove()
    call s:CloseWindowsBelow()
endfunction

function! s:WindowBufferNRs()
    let windowBufferNRs = [-1]
    let windowCount = winnr('$')
    let windowIndex = 1
    while windowIndex <= windowCount
        call add(windowBufferNRs, winbufnr(windowIndex))
        let windowIndex += 1
    endwhile
    return windowBufferNRs
endfunction

function! s:ColumnPrimaryWindow()
    let currentWindowNR = winnr()
    let windowBufferNRs = s:WindowBufferNRs()
    call remove(windowBufferNRs, currentWindowNR)
    echom join(windowBufferNRs)
    wincmd o
    let restoreWindowBufferNR = winnr()
    let windowIndex = 1
    while windowIndex < len(windowBufferNRs)
        let bufferNR = windowBufferNRs[windowIndex]
        if bufferNR != -1
            if windowIndex == 1
                vnew
            else
                new
            endif
            wincmd =
            execute 'buffer ' . bufferNR
            let windowIndex += 1
        endif
    endwhile
    execute restoreWindowBufferNR . 'wincmd w'
endfunction


" Tab buffer list
function! s:MaxBufferListHeight()
    return exists('g:litespace_buffer_list_height') ? g:litespace_buffer_list_height : 10
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
    let targetWindowNR = s:GetBufferTargetWindowNR(a:bufferNR)
    execute 'silent! bunload ' . a:bufferNR
    execute 'silent! bdelete ' . a:bufferNR
    if targetWindowNR != -1
        execute targetWindowNR . 'wincmd w'
    endif
endfunction

function! s:BufferTargetWindowVariableName()
    return 'litespace_target_window'
endfunction

function! s:GetBufferTargetWindowNR(bufferNR)
    return getbufvar(a:bufferNR, s:BufferTargetWindowVariableName(), -1)
endfunction

function! s:GetCurrentBufferLineEntry()
    let entry = getline(line('.'))
    let parts = split(entry, "\t")
    return parts
endfunction

function! s:GetCurrentBufferLineBufferNR()
    let parts = s:GetCurrentBufferLineEntry()
    return parts[0]
endfunction

function! s:RemoveCurrentBufferLineBufferNR()
    let bufferNR = bufnr('%')
    let lineCount = line('$')
    if lineCount > 0
        call s:RemoveBuffer(s:GetCurrentBufferLineBufferNR())
        setlocal modifiable
        normal! dd
        setlocal nomodifiable
    endif
    if lineCount <= 1
        call s:RemoveListBuffersWindow(bufferNR)
    endif
endfunction

function! s:OpenBuffer(splitBuffer)
    let bufferNR = s:GetCurrentBufferLineBufferNR()
    let targetWindowNR = s:GetBufferTargetWindowNR(bufnr('%'))
    if targetWindowNR != -1
        execute targetWindowNR . 'wincmd w'
        if a:splitBuffer == 0
            execute 'buffer ' . bufferNR
        elseif a:splitBuffer == 1
            execute 'split +buffer\ ' . bufferNR
        else
            execute 'vsplit +buffer\ ' . bufferNR
        endif
    endif
endfunction

function! s:GetBufferNames()
    let bufferNames = []
    let currentWindowNR = winnr()
    let currentWindowBufferNR = winbufnr(currentWindowNR)
    let bufferList = s:GetTabBufferList()
    if !empty(bufferList)
        for key in sort(keys(bufferList))
            let bufferNR = str2nr(key)
            if bufferNR != currentWindowBufferNR
                if !bufexists(bufferNR)
                    echoerr 'Stale buffer was not removed from list ' . bufferNR
                else
                    let bufferRawName = bufname(bufferNR)
                    let bufferName = bufferRawName
                    if empty(bufferRawName) && exists('g:litespace_show_unnamed') && g:litespace_show_unnamed
                        let bufferName = '[No Name]'
                    endif

                    if !empty(bufferName)
                        let briefName = fnamemodify(bufferName, ':t')
                        let bufferLine = key . "\t" . briefName
                        if bufferName !=? briefName
                            let bufferLine = bufferLine . "\t" . bufferName
                        endif
                        call add(bufferNames, bufferLine)
                    endif
                endif
            endif
        endfor
    endif
    return bufferNames
endfunction

function! s:AddListBuffersMappings()
    autocmd BufLeave <buffer> call <SID>RemoveListBuffersWindow(expand('<abuf>'))
    autocmd BufWinLeave <buffer> call <SID>RemoveListBuffersWindow(expand('<abuf>'))
    nnoremap <buffer> <C-c> :call <SID>RemoveListBuffersWindow(bufnr('%'))<CR>
    nnoremap <buffer> <C-[> :call <SID>RemoveListBuffersWindow(bufnr('%'))<CR>
    nnoremap <buffer> <CR> :call <SID>OpenBuffer(0)<CR>
    nnoremap <buffer> o :call <SID>OpenBuffer(0)<CR>
    nnoremap <buffer> s :call <SID>OpenBuffer(1)<CR>
    nnoremap <buffer> v :call <SID>OpenBuffer(2)<CR>
    nnoremap <buffer> d :call <SID>RemoveCurrentBufferLineBufferNR()<CR>
endfunction

function! s:RedisplayBufferNames(bufferNames)
    setlocal modifiable
    normal ggdG
    call append(0, a:bufferNames)
    normal ddgg
    setlocal nomodifiable
endfunction

function! s:DisplayBufferNames(bufferNames, targetWindowNR)
    if empty(a:bufferNames)
        echom 'Buffer list is empty'
    else
        new
        wincmd J
        let buffer_list_height = min([s:MaxBufferListHeight(), len(a:bufferNames)])
        execute buffer_list_height . 'wincmd _'

        setlocal modifiable
        normal ggdG
        call append(0, a:bufferNames)
        normal ddgg

        let bufferListNR = bufnr('%')
        call setbufvar(bufferListNR, s:BufferTargetWindowVariableName(), a:targetWindowNR)
        call s:RemoveBuffer(bufferListNR)

        call s:AddListBuffersMappings()

        setlocal buftype=nofile
        setlocal nomodifiable
    endif
endfunction

function! s:ListBuffers()
    let currentWindowNR = winnr()
    call s:DisplayBufferNames(s:GetBufferNames(), currentWindowNR)
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
nnoremap <unique> <Leader>wo    :call <SID>ColumnOnlyWindow()<CR>
nnoremap <unique> <Leader>wp    :call <SID>ColumnPrimaryWindow()<CR>
nnoremap <unique> <Leader>ls    :call <SID>ListBuffers()<CR>
