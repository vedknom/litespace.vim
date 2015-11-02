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

function! s:ColumnPrimaryWindowWith(primary, other)
  let l:primary = a:primary
  let l:other = a:other
  let l:curwinnr = winnr()
  let l:winbufnrs = s:WindowBufferNRs()
  call remove(l:winbufnrs, l:curwinnr)
  " echom join(l:winbufnrs)
  wincmd o
  let l:restorewinnr = winnr()
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
  execute l:restorewinnr . 'wincmd w'
endfunction

function! s:ColumnPrimaryWindowHorizontal()
  call s:ColumnPrimaryWindowWith('rightbelow new', 'leftabove vnew')
endfunction

function! s:ColumnPrimaryWindowVertical()
  call s:ColumnPrimaryWindowWith('rightbelow vnew', 'leftabove new')
endfunction

" State
let s:state = {
\ }

let s:tab_buffer_set_key = 'litespace_buffer_set'

" Utility
function! s:SortInts(lhs, rhs)
  return a:lhs - a:rhs
endfunction

" Entry
function! s:EntryNew(name, path, bufnr)
  let l:self = {
    \ 'name': a:name,
    \ 'path': a:path,
    \ 'bufnr': a:bufnr
  \ }
  return l:self
endfunction

function! s:EntryFromCurrentLine()
  let l:line = getline(line('.'))
  let l:parts = split(l:line, '\s*"\s*')
  let l:entry = s:EntryNew(l:parts[0], l:parts[1], l:parts[2])
  return l:entry
endfunction

function! s:EntryGetBufnrFromCurrentLine()
  let l:entry = s:EntryFromCurrentLine()
  return l:entry.bufnr
endfunction

" BufferList
function! s:BufferListNew()
  let l:bufferList = {}
  let l:bufferList.type = 'BufferList'
  let l:bufferList.bufnrs = {}
  return l:bufferList
endfunction

function! s:IsBufferListType(object)
  let l:object = a:object
  return type(l:object) == type({}) && get(l:object, 'type') == 'BufferList'
endfunction

function! s:BufferListFromCurrentTab()
  let l:tabnr = tabpagenr()
  let l:bufferListVar = gettabvar(l:tabnr, s:tab_buffer_set_key)
  if !s:IsBufferListType(l:bufferListVar)
    let l:bufferList = s:BufferListNew()
    call settabvar(l:tabnr, s:tab_buffer_set_key, l:bufferList)
  else
    let l:bufferList = l:bufferListVar
  endif
  return l:bufferList
endfunction

function! s:BufferListFromAll()
  let l:tabnr = tabpagenr()
  redir => l:allbufs
    silent! buffers
  redir END
  let l:getbufnr = "substitute(v:val, '^[ ]*\\([0-9]*\\)[ ]*.*$', '\\1', 'g')"
  let l:allbufnrs = map(split(l:allbufs, '\n'), l:getbufnr)

  let l:bufferList = s:BufferListNew()
  for l:bufnr in l:allbufnrs
    call s:bufferListAdd(l:bufferList, l:bufnr)
  endfor
  return l:bufferList
endfunction

function! s:bufferListAdd(self, bufnr)
  let l:self = a:self
  let l:bufnr = a:bufnr
  let l:self.bufnrs[l:bufnr] = l:bufnr
endfunction

function! s:bufferListRemove(self, bufnr)
  let l:self = a:self
  let l:bufnr = a:bufnr
  if has_key(l:self.bufnrs, l:bufnr)
    unlet l:self.bufnrs[l:bufnr]
  endif
endfunction

function! s:bufferListClear(self)
  let l:self = a:self
  let l:self.bufnrs = {}
endfunction

function! s:bufferListGetEntries(self, skipbufnr)
  let l:self = a:self
  let l:skipbufnr = a:skipbufnr
  let l:entries = []
  let l:bufnrs = keys(l:self.bufnrs)
  if !empty(l:bufnrs)
    for l:key in sort(l:bufnrs, function("s:SortInts"))
      let l:bufnr = str2nr(l:key)
      if l:bufnr != l:skipbufnr 
        if !bufexists(l:bufnr) || !buflisted(l:bufnr)
          " echom 'Stale buffer was not removed from list ' . l:bufnr
          " unlet l:self[l:key]
        else
          let l:bufferRawName = bufname(l:bufnr)
          let l:bufferName = bufferRawName
          if empty(bufferRawName) && exists('g:litespace_show_unnamed') && g:litespace_show_unnamed
            let l:bufferName = '[No Name]'
          endif

          if !empty(l:bufferName)
            let l:briefName = fnamemodify(l:bufferName, ':t')
            let l:entry = s:EntryNew(l:briefName, l:bufferName, l:key)
            call add(l:entries, l:entry)
          endif
        endif
      endif
    endfor
  endif
  return l:entries
endfunction

function! s:bufferListGetLines(self, skipbufnr)
  let l:self = a:self
  let l:skipbufnr = a:skipbufnr
  let l:entries = s:bufferListGetEntries(l:self, l:skipbufnr)
  let l:maxNameLength = 0
  for l:entry in l:entries
    if len(l:entry.name) > l:maxNameLength
      let l:maxNameLength = len(l:entry.name)
    endif
  endfor

  let l:lines = []
  let l:nameWidth = (((l:maxNameLength + 3) / 4) + 1) * 4
  let l:stringFormat = '%-' . l:nameWidth . 's"%s" %d'
  for l:entry in l:entries
    let l:line = printf(l:stringFormat, l:entry.name, l:entry.path, l:entry.bufnr)
    call add(l:lines, l:line)
  endfor

  return l:lines
endfunction

" Space
function! s:SpaceDirectory()
  return '.litespace'
endfunction

function! s:SpaceFilePathFor(filename)
  let l:directory = s:SpaceDirectory()
  let l:filename = a:filename
  let l:filepath = printf('%s/%s', directory, l:filename)
  return l:filepath
endfunction

function! s:SpaceWithBufferList(bufferList)
  let l:bufferList = a:bufferList
  let l:entries = s:bufferListGetEntries(l:bufferList, -1)
  let l:paths = map(l:entries, "v:val.path")
  return s:SpaceNew(l:paths)
endfunction

function! s:SpaceLoadFrom(spacename, mustexist)
  let l:spacename = a:spacename
  let l:mustexist = a:mustexist
  let l:paths = []
  if !empty(l:spacename)
    let l:filepath = s:SpaceFilePathFor(l:spacename)
    if filereadable(l:filepath)
      let l:paths = readfile(l:filepath)
    elseif l:mustexist
      echoerr 'File is not readable ' . l:filepath
    endif
  endif
  let l:self = s:SpaceNew(l:paths)
  return l:self
endfunction

function! s:SpaceNew(paths)
  let l:paths = a:paths
  let l:self = {
    \ 'paths': copy(l:paths)
  \ }
  return l:self
endfunction

function! s:spaceSave(self, filename)
  let l:self = a:self
  let l:filename = a:filename
  let l:filepath = s:SpaceFilePathFor(l:filename)

  let l:directory = s:SpaceDirectory()
  if !isdirectory(l:directory)
    if filereadable(l:directory)
      echoerr l:directory . ' exists as a file!'
      return
    endif
    call mkdir(l:directory, 'p')
  endif

  call writefile(l:self.paths, l:filepath)
endfunction

function! s:spaceAddPath(self, path)
  let l:self = a:self
  let l:path = a:path
  let l:paths = l:self.paths 
  let l:self.paths = sort(add(l:paths, l:path))
endfunction

function! s:spaceLoadBuffers(self)
  let l:self = a:self
  let l:oldbufnr = bufnr('%')

  let l:paths = l:self.paths
  for l:path in l:paths
    let l:strippped = l:path
    let l:strippped = substitute(l:strippped, '^\s*', '', '')
    let l:strippped = substitute(l:strippped, '\s*$', '', '')
    execute 'edit ' . escape(l:strippped, ' ')
  endfor

  execute 'buffer ' . l:oldbufnr
endfunction

" ListWindow
function! s:ListWindowMaxHeight()
  return exists('g:litespace_buffer_list_height') ? g:litespace_buffer_list_height : 10
endfunction

function! s:ListWindowNew()
  " .bufferList
  let l:self = {
    \ 'srcwinnr': -1
  \ }
  return l:self
endfunction

function! s:ListWindowInstance()
  let l:key = 'window'
  if !has_key(s:state, l:key)
    let s:state[l:key] = s:ListWindowNew()
  endif
  return s:state[l:key]
endfunction

function! s:ListWindowDisplay(bufferList, srcwinnr)
  let l:self = s:ListWindowInstance()
  let l:shown = l:self.srcwinnr != -1
  let l:srcwinnr = l:shown ? l:self.srcwinnr : a:srcwinnr
  let l:bufferList = a:bufferList
  if l:shown
    call s:ListWindowRemove(bufnr('%'))
    return s:ListWindowDisplay(l:bufferList, l:srcwinnr)
  endif

  let l:skipbufnr = winbufnr(l:srcwinnr)
  let l:lines = s:bufferListGetLines(l:bufferList, l:skipbufnr)
  if empty(l:lines)
    echom 'Buffer list is empty'
    let l:self.srcwinnr = -1
  else
    botright new
    let l:self.srcwinnr = l:srcwinnr
    let l:self.bufferList = l:bufferList
    let l:winheigt = min([s:ListWindowMaxHeight(), len(l:lines)])
    execute l:winheigt . 'wincmd _'

    setlocal modifiable
    normal ggdG
    call append(0, l:lines)
    normal ddgg

    call s:bufferListRemove(l:self.bufferList, bufnr('%'))
    call s:ListWindowSetupMappings()

    setlocal buftype=nofile
    setlocal nomodifiable
  endif
endfunction

function! s:ListWindowRemove(bufnr)
  let l:self = s:ListWindowInstance()
  let l:bufnr = a:bufnr

  silent execute 'silent! bunload ' . a:bufnr
  silent execute 'silent! bdelete ' . a:bufnr
  if l:self.srcwinnr != -1
    execute l:self.srcwinnr . 'wincmd w'
    let l:self.srcwinnr = -1
  endif
endfunction

function! s:ListWindowOpenSelectedBuffer(splitStyle)
  let l:self = s:ListWindowInstance()
  let l:bufnr = s:EntryGetBufnrFromCurrentLine()
  let l:splitStyle = a:splitStyle

  if l:self.srcwinnr != -1
    execute l:self.srcwinnr . 'wincmd w'
    if l:splitStyle == 0
      execute 'buffer ' . l:bufnr
    elseif l:splitStyle == 1
      execute 'split +buffer\ ' . l:bufnr
    else
      execute 'vsplit +buffer\ ' . l:bufnr
    endif
  endif
endfunction

function! s:ListWindowRemoveSelectedBuffer()
  let l:bufnr = bufnr('%')
  let l:lineCount = line('$')

  let l:self = s:ListWindowInstance()
  if l:lineCount > 0
    let l:bufferList = l:self.bufferList
    let l:rmbufnr = s:EntryGetBufnrFromCurrentLine()
    call s:bufferListRemove(l:bufferList, l:rmbufnr)
    setlocal modifiable
    normal! dd
    setlocal nomodifiable
  endif
  if l:lineCount <= 1
    call s:ListWindowRemove(l:bufnr)
  endif
endfunction

function! s:ListWindowRemoveAllBuffers()
  let l:bufnr = bufnr('%')

  let l:self = s:ListWindowInstance()
  let l:bufferList = l:self.bufferList
  call s:bufferListClear(l:bufferList)
  call s:ListWindowRemove(l:bufnr)
endfunction

function! s:ListWindowRefreshToCurrentTab()
  let l:bufnr = bufnr('%')
  let windowCount = winnr('$')

  let l:self = s:ListWindowInstance()
  let l:bufferList = l:self.bufferList
  let l:srcwinnr = l:self.srcwinnr
  call s:ListWindowRemoveAllBuffers()
  let l:winnr = 1
  while l:winnr <= windowCount
    let l:bufnr = winbufnr(l:winnr)
    if l:bufnr != -1
      call s:bufferListAdd(l:bufferList, l:bufnr)
    endif
    let l:winnr = l:winnr + 1
  endwhile
  call s:ListWindowDisplay(l:bufferList, l:srcwinnr)
endfunction

function! s:ListWindowSetupMappings()
  autocmd BufLeave      <buffer>    call  <SID>ListWindowRemove(expand('<abuf>'))
  autocmd BufWinLeave   <buffer>    call  <SID>ListWindowRemove(expand('<abuf>'))
  nnoremap <silent> <buffer> <C-c>  :call <SID>ListWindowRemove(bufnr('%'))<CR>
  nnoremap <silent> <buffer> <C-[>  :call <SID>ListWindowRemove(bufnr('%'))<CR>
  nnoremap <silent> <buffer> q      :call <SID>ListWindowRemove(bufnr('%'))<CR>
  nnoremap <silent> <buffer> <CR>   :call <SID>ListWindowOpenSelectedBuffer(0)<CR>
  nnoremap <silent> <buffer> o      :call <SID>ListWindowOpenSelectedBuffer(0)<CR>
  nnoremap <silent> <buffer> s      :call <SID>ListWindowOpenSelectedBuffer(1)<CR>
  nnoremap <silent> <buffer> v      :call <SID>ListWindowOpenSelectedBuffer(2)<CR>
  nnoremap <silent> <buffer> d      :call <SID>ListWindowRemoveSelectedBuffer()<CR>
  nnoremap <silent> <buffer> D      :call <SID>ListWindowRemoveAllBuffers()<CR>
  nnoremap <silent> <buffer> r      :call <SID>ListWindowRefreshToCurrentTab()<CR>
  nnoremap <silent> <buffer> S      :call <SID>ListWindowSaveSpace()<CR>
endfunction

function! s:ListWindowDisplayTabBufferList()
  call s:ListWindowDisplay(s:BufferListFromCurrentTab(), winnr())
endfunction

function! s:ListWindowDisplayAllBufferList()
  call s:ListWindowDisplay(s:LiteSpaceGetAllBufferList(), winnr())
endfunction

function! s:ListWindowSaveSpace()
  let l:self = s:ListWindowInstance()
  let l:space = s:SpaceWithBufferList(l:self.bufferList)
  let l:filename = input('Save space name: ')
  if len(l:filename) > 0
    call s:spaceSave(l:space, l:filename)
  endif
endfunction

" LiteSpace
function! s:LiteSpaceGetAllBufferList()
  let l:key = 'all'
  if !has_key(s:state, l:key)
    let s:state[l:key] = s:BufferListFromAll()
  endif
  return s:state[l:key]
endfunction

function! s:LiteSpaceAddBufnr(bufnr)
  let l:bufnr = a:bufnr
  let l:tabbuflist = s:BufferListFromCurrentTab()
  call s:bufferListAdd(l:tabbuflist, l:bufnr)
  let l:allbuflist = s:LiteSpaceGetAllBufferList()
  call s:bufferListAdd(l:allbuflist, l:bufnr)
endfunction

function! s:LiteSpaceRemoveBufnr(bufnr)
  let l:bufnr = a:bufnr
  let l:tabbuflist = s:BufferListFromCurrentTab()
  call s:bufferListRemove(l:tabbuflist, l:bufnr)
  let l:allbuflist = s:LiteSpaceGetAllBufferList()
  call s:bufferListRemove(l:allbuflist, l:bufnr)
endfunction

function! s:LiteSpacePromptSpaceName(action)
  let l:action = a:action
  let l:oldpath = &path
  let l:oldwildmenu = &wildmenu
  let l:directory = s:SpaceDirectory()
  let &wildmenu = 1
  execute 'setlocal path=' . l:directory
  let l:spacename = input(l:action . ' space named: ', '', 'file_in_path')
  execute 'setlocal path=' . l:oldpath 
  let &wildmenu = l:oldwildmenu
  return l:spacename
endfunction

function! s:LiteSpacePromptLoadSpace()
  let l:oldbufnr = bufnr('%')
  let l:spacename = s:LiteSpacePromptSpaceName('Load')
  if !empty(l:spacename)
    let l:space = s:SpaceLoadFrom(l:spacename, 1)
    call s:spaceLoadBuffers(l:space)
  endif
endfunction

function! s:LiteSpacePromptAppendToSpace()
  let l:spacename = s:LiteSpacePromptSpaceName('Append')
  if !empty(l:spacename)
    let l:bufnr = bufnr('%')
    let l:bufferName = bufname(l:bufnr)
    if !empty(l:bufferName)
      let l:space = s:SpaceLoadFrom(l:spacename, 0)
      call s:spaceAddPath(l:space, l:bufferName)
      call s:spaceSave(l:space, l:spacename)
    endif
  endif
endfunction

" LiteSpace
augroup LiteSpace
  autocmd!
  autocmd BufEnter,BufWinEnter * call <SID>LiteSpaceAddBufnr(expand('<abuf>'))
  " autocmd BufUnload,BufDelete,BufWipeout * call <SID>LiteSpaceRemoveBufnr(expand('<abuf>'))
  autocmd BufUnload * call <SID>LiteSpaceRemoveBufnr(expand('<abuf>'))
  autocmd FileType qf call <SID>LiteSpaceRemoveBufnr(expand('<abuf>'))
augroup END

nnoremap <unique> <silent> <Leader>tn     :tabnew<CR>
nnoremap <unique> <silent> <Leader>wt     :tab split<CR>
nnoremap <unique> <silent> <Leader>ws     :tab split<CR>:rightbelow new<CR>:wincmd w<CR>
nnoremap <unique> <silent> <Leader>wv     :tab split<CR>:rightbelow vnew<CR>:wincmd w<CR>

nnoremap <unique> <silent> <Leader>wm1    :call <SID>MoveToWindow(1)<CR>
nnoremap <unique> <silent> <Leader>wm2    :call <SID>MoveToWindow(2)<CR>
nnoremap <unique> <silent> <Leader>wm3    :call <SID>MoveToWindow(3)<CR>
nnoremap <unique> <silent> <Leader>wm4    :call <SID>MoveToWindow(4)<CR>

nnoremap <unique> <silent> <Leader>wo     :call <SID>ColumnOnlyWindow()<CR>
nnoremap <unique> <silent> <Leader>wpk    :call <SID>ColumnPrimaryWindowHorizontal()<CR>
nnoremap <unique> <silent> <Leader>wph    :call <SID>ColumnPrimaryWindowVertical()<CR>

nnoremap <unique> <silent> <Leader>lsa    :call <SID>ListWindowDisplayAllBufferList()<CR>
nnoremap <unique> <silent> <Leader>lsl    :call <SID>ListWindowDisplayTabBufferList()<CR>
nnoremap <unique> <silent> <Leader>lss    :call <SID>LiteSpacePromptLoadSpace()<CR>
nnoremap <unique> <silent> <Leader>lsp    :call <SID>LiteSpacePromptAppendToSpace()<CR>
