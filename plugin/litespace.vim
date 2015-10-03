" litespace.vim - Lightweight workspace manager
" " vim: set sw=2 ts=2 sts=2 fdm=indent fml=0:
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

function! s:CloseWindows(movement)
  while 1
    let prevWinNR = winnr()
    execute 'wincmd ' . a:movement
    if winnr() == prevWinNR
      break
    endif
  endwhile
  while 1
    if getwinvar(winnr(), 'litespace_keep_window', 0)
      break
    endif
    wincmd c
  endwhile
endfunction

function! s:ColumnOnlyWindow()
  let windowNR = winnr()
  call setwinvar(windowNR, 'litespace_keep_window', 1)
  call s:CloseWindows('k')
  call s:CloseWindows('j')
  unlet w:litespace_keep_window
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
  " echom join(windowBufferNRs)
  wincmd o
  let restoreWindowBufferNR = winnr()
  let windowIndex = 1
  while windowIndex < len(windowBufferNRs)
    let bufferNR = windowBufferNRs[windowIndex]
    if bufferNR != -1
      if windowIndex == 1
        rightbelow vnew
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

function! s:GetAllBufferList()
  redir => l:allbufs
    silent! buffers
  redir END
  let l:getbufnr = "substitute(v:val, '^[ ]*\\([0-9]*\\)[ ]*.*$', '\\1', 'g')"
  let l:allbufnrs = map(split(l:allbufs, '\n'), l:getbufnr)
  return l:allbufnrs
endfunction

function! s:GetTabBufferSet()
  let tabNR = tabpagenr()
  let bufferSet = {}
  let bufferSetVar = gettabvar(tabNR, 'litespace_buffer_set')
  if type(bufferSetVar) == type(bufferSet)
    let bufferSet = bufferSetVar
  elseif empty(bufferSetVar)
    call settabvar(tabNR, 'litespace_buffer_set', bufferSet)
  endif
  return bufferSet " Set of bufnrs
endfunction

function! s:ClearTabBuffers()
  let tabNR = tabpagenr()
  call settabvar(tabNR, 'litespace_buffer_set', {})
endfunction

function! s:AddBufferNR(bufferNR)
  let bufferNR = a:bufferNR
  let bufferSet = s:GetTabBufferSet()
  let bufferSet[bufferNR] = bufferNR
endfunction

function! s:GetTabBufferList()
  let bufferSet = s:GetTabBufferSet()
  return keys(bufferSet)
endfunction

function! s:AddBuffer()
  let bufNR = expand('<abuf>')
  call s:AddBufferNR(bufNR)
endfunction

function! s:RemoveBuffer(bufferNR)
  let bufferSet = s:GetTabBufferSet()
  if has_key(bufferSet, a:bufferNR)
    unlet bufferSet[a:bufferNR]
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

function! s:RemoveAllBufferLineBufferNR()
  let bufferNR = bufnr('%')
  call s:ClearTabBuffers()
  call s:RemoveListBuffersWindow(bufferNR)
endfunction

function! s:RefreshToCurrentTabBufferNR()
  let bufferNR = bufnr('%')
  let targetWindowNR = s:GetBufferTargetWindowNR(bufferNR)
  call s:RemoveAllBufferLineBufferNR()
  let windowCount = winnr('$')
  let windowNR = 1
  while windowNR <= windowCount
    let bufferNR = winbufnr(windowNR)
    if bufferNR != -1
      call s:AddBufferNR(bufferNR)
    endif
    let windowNR = windowNR + 1
  endwhile
  call s:DisplayBufferList(s:GetTabBufferList(), targetWindowNR)
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

function! s:SortInts(lhs, rhs)
  return a:lhs - a:rhs
endfunction

function! s:GetBufferNames(bufferList)
  let bufferNames = []
  let currentWindowNR = winnr()
  let currentWindowBufferNR = winbufnr(currentWindowNR)
  let l:bufferList = a:bufferList
  if !empty(l:bufferList)
    for key in sort(bufferList, function("s:SortInts"))
      let bufferNR = str2nr(key)
      if bufferNR != currentWindowBufferNR
        if !bufexists(bufferNR) || !buflisted(bufferNR)
          " echom 'Stale buffer was not removed from list ' . bufferNR
          " unlet bufferList[key]
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
  nnoremap <silent> <buffer> <C-c> :call <SID>RemoveListBuffersWindow(bufnr('%'))<CR>
  nnoremap <silent> <buffer> <C-[> :call <SID>RemoveListBuffersWindow(bufnr('%'))<CR>
  nnoremap <silent> <buffer> q :call <SID>RemoveListBuffersWindow(bufnr('%'))<CR>
  nnoremap <silent> <buffer> <CR> :call <SID>OpenBuffer(0)<CR>
  nnoremap <silent> <buffer> o :call <SID>OpenBuffer(0)<CR>
  nnoremap <silent> <buffer> s :call <SID>OpenBuffer(1)<CR>
  nnoremap <silent> <buffer> v :call <SID>OpenBuffer(2)<CR>
  nnoremap <silent> <buffer> d :call <SID>RemoveCurrentBufferLineBufferNR()<CR>
  nnoremap <silent> <buffer> D :call <SID>RemoveAllBufferLineBufferNR()<CR>
  nnoremap <silent> <buffer> r :call <SID>RefreshToCurrentTabBufferNR()<CR>
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

function! s:DisplayBufferList(bufferList, targetWindowNR)
  call s:DisplayBufferNames(s:GetBufferNames(a:bufferList), a:targetWindowNR)
endfunction

function! s:ListTabBuffers()
  let currentWindowNR = winnr()
  call s:DisplayBufferList(s:GetTabBufferList(), currentWindowNR)
endfunction

function! s:ListAllBuffers()
  let currentWindowNR = winnr()
  call s:DisplayBufferList(s:GetAllBufferList(), currentWindowNR)
endfunction

augroup LiteSpace
  autocmd!
  autocmd BufEnter,BufWinEnter * call <SID>AddBuffer()
  " autocmd BufUnload,BufDelete,BufWipeout * call <SID>RemoveBuffer(expand('<abuf>'))
  autocmd BufUnload * call <SID>RemoveBuffer(expand('<abuf>'))
  autocmd FileType qf call <SID>RemoveBuffer(expand('<abuf>'))
augroup END

nnoremap <unique> <silent> <Leader>tn  :tabnew<CR>
nnoremap <unique> <silent> <Leader>wm1   :call <SID>MoveToWindow(1)<CR>
nnoremap <unique> <silent> <Leader>wm2   :call <SID>MoveToWindow(2)<CR>
nnoremap <unique> <silent> <Leader>wm3   :call <SID>MoveToWindow(3)<CR>
nnoremap <unique> <silent> <Leader>wm4   :call <SID>MoveToWindow(4)<CR>
nnoremap <unique> <silent> <Leader>wt  :tab split<CR>
nnoremap <unique> <silent> <Leader>wS  :tab split<CR>:vnew<CR>:wincmd w<CR>
nnoremap <unique> <silent> <Leader>wo  :call <SID>ColumnOnlyWindow()<CR>
nnoremap <unique> <silent> <Leader>wp  :call <SID>ColumnPrimaryWindow()<CR>
nnoremap <unique> <silent> <Leader>lsa  :call <SID>ListAllBuffers()<CR>
nnoremap <unique> <silent> <Leader>lsl  :call <SID>ListTabBuffers()<CR>
