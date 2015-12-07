" vim: set sw=2 ts=2 sts=2 fdm=indent fml=0:

if exists('g:autoloaded_litespace') && g:autoloaded_litespace
  finish
endif

let g:autoloaded_litespace = 1

" State
let s:state = {
\ }

let s:tab_buffer_set_key = 'litespace_buffer_set'

" Utility
function! s:Funcname(name)
  let l:sid = matchstr(expand('<sfile>'), '<SNR>\zs\d\+\ze_Fn$')
  let l:funcname = printf('<SNR>%d_%s', l:sid, a:name)
  return l:funcname
endfunction

function! s:Fn(name)
  let l:name = a:name
  let l:funcname = s:Funcname(l:name)
  return function(l:funcname)
endfunction

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
  let l:self = {
    \ 'type': 'BufferList',
    \ 'bufnrs': {},
    \ 'frozen': 0,
    \ 'tabname': ''
  \ }
  return l:self
endfunction

function! s:IsBufferListType(object)
  let l:object = a:object
  return type(l:object) == type({}) && get(l:object, 'type') == 'BufferList'
endfunction

function! s:BufferListFromCurrentTab()
  let l:tabnr = tabpagenr()
  return s:BufferListFromTab(l:tabnr)
endfunction

function! s:BufferListFromTab(tabnr)
  let l:tabnr = a:tabnr
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

function! s:bufferListGetTabName(self, defaultTabnr)
  let l:self = a:self
  let l:defaultTabnr = string(a:defaultTabnr)
  let l:tabname = !empty(l:self.tabname) ? l:self.tabname : l:defaultTabnr
  return l:tabname
endfunction

function! s:bufferListFrozen(self)
  let l:self = a:self
  return l:self.frozen
endfunction

function! s:bufferListSetFrozen(self, flag)
  let l:self = a:self
  let l:flag = a:flag
  let l:self.frozen = l:flag
endfunction

function! s:bufferListToggleFrozen(self)
  let l:self = a:self
  call s:bufferListSetFrozen(l:self, !s:bufferListFrozen(l:self))
endfunction

function! s:bufferListAdd(self, bufnr)
  let l:self = a:self
  if !s:bufferListFrozen(l:self)
    let l:bufnr = a:bufnr
    let l:self.bufnrs[l:bufnr] = l:bufnr
  endif
endfunction

function! s:bufferListRemove(self, bufnr)
  let l:self = a:self
  if !s:bufferListFrozen(l:self)
    let l:bufnr = a:bufnr
    if has_key(l:self.bufnrs, l:bufnr)
      unlet l:self.bufnrs[l:bufnr]
    endif
  endif
endfunction

function! s:bufferListClear(self)
  let l:self = a:self
  if !s:bufferListFrozen(l:self)
    let l:self.bufnrs = {}
  endif
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
    let l:path = s:LitespaceDisplayListStyle() == 0 ? l:entry.path : ''
    let l:line = printf(l:stringFormat, l:entry.name, l:path, l:entry.bufnr)
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
    \ 'paths': []
  \ }
  call s:spaceSetPaths(l:self, l:paths)
  return l:self
endfunction

function! s:spaceSetPaths(self, paths)
  let l:self = a:self
  let l:paths = a:paths
  let l:self.paths = uniq(sort(copy(l:paths)))
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

function! s:spaceMerge(self, other)
  let l:self = a:self
  let l:other = a:other
  call s:spaceSetPaths(l:self, l:self.paths + l:other.paths)
endfunction

" BaseListWindow
function! s:BaseListWindowMaxHeight()
  return exists('g:litespace_buffer_list_height') ? g:litespace_buffer_list_height : 10
endfunction

function! s:BaseListWindowNew()
  let l:self = {
    \ 'srcwinnr': -1
  \ }
  return l:self
endfunction

function! s:baseListWindowRemove(self, bufnr)
  let l:self = a:self
  let l:bufnr = a:bufnr

  silent execute 'silent! bunload ' . a:bufnr
  silent execute 'silent! bdelete ' . a:bufnr
  if l:self.srcwinnr != -1
    execute l:self.srcwinnr . 'wincmd w'
    let l:self.srcwinnr = -1
  endif
endfunction

" ListWindow
function! s:ListWindowNew()
  " .bufferList
  let l:self = s:BaseListWindowNew()
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
    let l:winheigt = min([s:BaseListWindowMaxHeight(), len(l:lines)])
    execute l:winheigt . 'wincmd _'

    setlocal modifiable
    normal ggdG
    call append(0, l:lines)
    normal ddgg

    call s:bufferListRemove(l:self.bufferList, bufnr('%'))
    call s:ListWindowSetupMappings()

    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal nomodifiable
  endif
endfunction

function! s:ListWindowRemove(bufnr)
  let l:self = s:ListWindowInstance()
  let l:bufnr = a:bufnr
  call s:baseListWindowRemove(l:self, l:bufnr)
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
  let l:frozen = 0
  if l:lineCount > 0
    let l:bufferList = l:self.bufferList
    let l:frozen = s:bufferListFrozen(l:bufferList)
    if !l:frozen
      let l:rmbufnr = s:EntryGetBufnrFromCurrentLine()
      call s:bufferListRemove(l:bufferList, l:rmbufnr)
      setlocal modifiable
      normal! dd
      setlocal nomodifiable
    endif
  endif
  if l:lineCount <= 1 && !l:frozen
    call s:ListWindowRemove(l:bufnr)
  endif
endfunction

function! s:ListWindowRemoveAllBuffers()
  let l:bufnr = bufnr('%')

  let l:self = s:ListWindowInstance()
  let l:bufferList = l:self.bufferList
  let l:frozen = s:bufferListFrozen(l:bufferList)
  if !l:frozen
    call s:bufferListClear(l:bufferList)
    call s:ListWindowRemove(l:bufnr)
  endif
endfunction

function! s:ListWindowRefreshToCurrentTab()
  let l:bufnr = bufnr('%')
  let windowCount = winnr('$')

  let l:self = s:ListWindowInstance()
  let l:bufferList = l:self.bufferList
  " let l:frozen = s:bufferListFrozen(l:bufferList)
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

function! s:ListWindowCycleListStyle()
  let l:self = s:ListWindowInstance()

  call s:LitespaceCycleListStyle()
  let l:bufferList = l:self.bufferList
  let l:srcwinnr = l:self.srcwinnr
  call s:ListWindowDisplay(l:bufferList, l:srcwinnr)
endfunction

function! s:ListWindowToggleFreezeBufferList()
  let l:self = s:ListWindowInstance()
  let l:bufferList = l:self.bufferList
  call s:bufferListToggleFrozen(l:bufferList)
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
  nnoremap <silent> <buffer> R      :call <SID>ListWindowToggleFreezeBufferList()<CR>
  nnoremap <silent> <buffer> C      :call <SID>ListWindowCycleListStyle()<CR>
  nnoremap <silent> <buffer> S      :call <SID>ListWindowSaveSpace()<CR>
endfunction

function! s:ListWindowDisplayTabBufferList()
  call s:ListWindowDisplay(s:BufferListFromCurrentTab(), winnr())
endfunction

function! s:ListWindowDisplayAllBufferList()
  call s:ListWindowDisplay(s:LitespaceGetAllBufferList(), winnr())
endfunction

function! s:ListWindowSaveSpace()
  let l:self = s:ListWindowInstance()
  let l:space = s:SpaceWithBufferList(l:self.bufferList)
  let l:filename = input('Save space name: ')
  if len(l:filename) > 0
    call s:spaceSave(l:space, l:filename)
  endif
endfunction

" TabListWindow
function! s:TabListEntries()
  let l:entries = []
  let l:curtabnr = tabpagenr()
  for l:i in range(tabpagenr('$'))
    let l:tabnr = l:i + 1
    if l:tabnr != l:curtabnr
      let l:bufferList = s:BufferListFromTab(l:tabnr)
      let l:tabname = s:bufferListGetTabName(l:bufferList, l:tabnr)
      let l:entry = [l:tabnr, l:tabname]
      call add(l:entries, l:entry)
    endif
  endfor
  return l:entries
endfunction

function! LitespaceTabListNameCompletion(arglead, cmdline, cursorpos)
  let l:entries = s:TabListEntries()
  let l:candidates = map(l:entries, 'v:val[1]')
  let l:result = join(l:candidates, "\n")
  return l:result
endfunction

function! s:TabListPromptGoto()
  let l:oldwildmenu = &wildmenu
  let &wildmenu = 1
  call inputsave()
  let l:tabname = input('Goto tab: ', '', 'custom,LitespaceTabListNameCompletion')
  call inputrestore()
  let &wildmenu = l:oldwildmenu
  let l:entries = s:TabListEntries()
  let l:name2tabnr = {}
  for l:entry in l:entries
    let l:name2tabnr[l:entry[1]] = l:entry[0]
  endfor
  let l:tabnr = l:name2tabnr[l:tabname]
  execute 'tabnext ' . l:tabnr
endfunction

function! s:TabListWindowNew()
  let l:self = s:BaseListWindowNew()
  return l:self
endfunction

function! s:TabListWindowInstance()
  let l:key = 'tabWindow'
  if !has_key(s:state, l:key)
    let s:state[l:key] = s:TabListWindowNew()
  endif
  return s:state[l:key]
endfunction

function! s:TabListWindowRemove(bufnr)
  let l:self = s:TabListWindowInstance()
  let l:bufnr = a:bufnr
  call s:baseListWindowRemove(l:self, l:bufnr)
endfunction

function! s:TabListWindowGoTo()
  let l:self = s:TabListWindowInstance()
  let l:line = getline('.')
  let l:splits = split(l:line, '#')
  if !empty(l:splits)
    let l:tabnr = str2nr(l:splits[-1])
    execute 'tabnext ' . l:tabnr
  endif
endfunction

function! s:TabListWindowDisplay(srcwinnr)
  let l:self = s:TabListWindowInstance()
  let l:shown = l:self.srcwinnr != -1
  let l:srcwinnr = l:shown ? l:self.srcwinnr : a:srcwinnr
  if l:shown
    return s:TabListWindowDisplay(l:srcwinnr)
  endif

  let l:lines = s:tabListWindowGetLines(l:self)
  if empty(l:lines)
    echom 'Tab list is empty'
    let l:self.srcwinnr = -1
  else
    botright new
    let l:self.srcwinnr = l:srcwinnr
    let l:winheigt = min([s:BaseListWindowMaxHeight(), len(l:lines)])
    execute l:winheigt . 'wincmd _'

    setlocal modifiable
    normal ggdG
    call append(0, l:lines)
    normal ddgg

    call s:TabListWindowSetupMappings()

    setlocal buftype=nofile
    setlocal bufhidden=delete
    setlocal nomodifiable
  endif
endfunction

function! s:TabListWindowSetupMappings()
  autocmd BufLeave      <buffer>    call  <SID>TabListWindowRemove(expand('<abuf>'))
  autocmd BufWinLeave   <buffer>    call  <SID>TabListWindowRemove(expand('<abuf>'))
  nnoremap <silent> <buffer> <C-c>  :call <SID>TabListWindowRemove(bufnr('%'))<CR>
  nnoremap <silent> <buffer> <C-[>  :call <SID>TabListWindowRemove(bufnr('%'))<CR>
  nnoremap <silent> <buffer> q      :call <SID>TabListWindowRemove(bufnr('%'))<CR>
  nnoremap <silent> <buffer> <CR>   :call <SID>TabListWindowGoTo()<CR>
endfunction

function! s:tabListWindowGetLines(self)
  let l:self = a:self
  let l:entries = []
  let l:curtabnr = tabpagenr()
  let l:maxNameLength = 0
  for l:i in range(tabpagenr('$'))
    let l:tabnr = l:i + 1
    if l:tabnr != l:curtabnr
      let l:bufferList = s:BufferListFromTab(l:tabnr)
      let l:tabname = s:bufferListGetTabName(l:bufferList, l:tabnr)
      let l:entry = [l:tabnr, l:tabname]
      call add(l:entries, l:entry)
      if len(l:entry[1]) > l:maxNameLength
        let l:maxNameLength = len(l:entry[1])
      endif
    endif
  endfor

  let l:lines = []
  let l:nameWidth = (((l:maxNameLength + 3) / 4) + 1) * 4
  let l:stringFormat = '%-' . l:nameWidth . 's#%d'
  for l:entry in l:entries
    let l:line = printf(l:stringFormat, l:entry[1], l:entry[0])
    call add(l:lines, l:line)
  endfor
  return l:lines
endfunction

" Litespace
function! s:LitespaceDisplayListStyle()
  if !exists('g:litespace_list_style')
    return 0
  endif
  return g:litespace_list_style
endfunction

function! s:LitespaceCycleListStyle()
  let l:listStyleCount = 2
  let g:litespace_list_style = (s:LitespaceDisplayListStyle() + 1) % l:listStyleCount
endfunction

function! s:LitespaceGetAllBufferList()
  let l:key = 'all'
  if !has_key(s:state, l:key)
    let s:state[l:key] = s:BufferListFromAll()
  endif
  return s:state[l:key]
endfunction

function! s:LitespaceAddBufnr(bufnr)
  let l:bufnr = a:bufnr
  let l:tabbuflist = s:BufferListFromCurrentTab()
  call s:bufferListAdd(l:tabbuflist, l:bufnr)
  let l:allbuflist = s:LitespaceGetAllBufferList()
  call s:bufferListAdd(l:allbuflist, l:bufnr)
endfunction

function! s:LitespaceRemoveBufnr(bufnr)
  let l:bufnr = a:bufnr
  let l:tabbuflist = s:BufferListFromCurrentTab()
  call s:bufferListRemove(l:tabbuflist, l:bufnr)
  let l:allbuflist = s:LitespaceGetAllBufferList()
  call s:bufferListRemove(l:allbuflist, l:bufnr)
endfunction

function! s:LitespacePromptSpaceName(action)
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

function! s:LitespaceSetFirstTabName(tabname)
  let l:tabname = a:tabname
  let l:bufferList = s:BufferListFromCurrentTab()
  if empty(l:bufferList.tabname)
    let l:bufferList.tabname = l:tabname
  endif
endfunction

function! s:LitespacePromptLoadSpace()
  let l:oldbufnr = bufnr('%')
  let l:spacename = s:LitespacePromptSpaceName('Load')
  if !empty(l:spacename)
    let l:space = s:SpaceLoadFrom(l:spacename, 1)
    call s:spaceLoadBuffers(l:space)
    call s:LitespaceSetFirstTabName(l:spacename)
  endif
endfunction

function! LitespaceTabLabel(tabnr)
  let l:tabnr = a:tabnr

  let l:bufnrlist = tabpagebuflist(l:tabnr)
  let l:tabpagewinnr = tabpagewinnr(l:tabnr)
  let l:origtabbufname = bufname(l:bufnrlist[l:tabpagewinnr - 1])
  if l:origtabbufname == ''
    let l:tabbufname = '[No Name]'
  else
    let l:tabbufname = fnamemodify(l:origtabbufname, ":t")
  endif

  let l:bufferList = s:BufferListFromTab(l:tabnr)
  let l:tabname = s:bufferListGetTabName(l:bufferList, l:tabnr)
  let l:label = printf('%s(%s)', l:tabname, l:tabbufname)

  return l:label
endfunction

function! s:LitespaceTabLine()
  let l:tabline = ''
  for i in range(tabpagenr('$'))
    " select the highlighting
    if i + 1 == tabpagenr()
      let l:tabline .= '%#TabLineSel#'
    else
      let l:tabline .= '%#TabLine#'
    endif

    let l:tabline .= '%' . (i + 1) . 'T'
    let l:tabline .= ' %{LitespaceTabLabel(' . (i + 1) . ')} '
  endfor

  " after the last tab fill with TabLineFill and reset tab page nr
  let l:tabline .= '%#TabLineFill#%T'

  " right-align the label to close the current tab page
  if tabpagenr('$') > 1
    let l:tabline .= '%=%#TabLine#%999XX'
  endif

  return l:tabline
endfunction

function! s:LitespacePromptLoadTabSpace()
  tabnew
  call s:LitespacePromptLoadSpace()
endfunction

function! s:LitespacePromptLoadSpaces()
  let l:oldbufnr = bufnr('%')
  let l:spacenames = []
  while 1
    let l:action = empty(l:spacenames) ? 'Load' : 'Add'
    let l:spacename = s:LitespacePromptSpaceName(l:action)
    if empty(l:spacename)
      break
    endif
    call add(l:spacenames, l:spacename)
  endwhile

  if !empty(l:spacenames)
    let l:space = s:SpaceNew([])
    for l:spacename in l:spacenames
      let l:other = s:SpaceLoadFrom(l:spacename, 1)
      call s:spaceMerge(l:space, l:other)
    endfor
    call s:spaceLoadBuffers(l:space)
  endif
endfunction

function! s:LitespacePromptEditSpace()
  let l:oldbufnr = bufnr('%')
  let l:spacename = s:LitespacePromptSpaceName('Edit')
  if !empty(l:spacename)
    let l:filepath = s:SpaceFilePathFor(l:spacename)
    execute 'edit ' . l:filepath
  endif
endfunction

function! s:LitespacePromptAppendToSpace()
  let l:spacename = s:LitespacePromptSpaceName('Append')
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

" API
function! litespace#addBufnr(bufnr)
  call s:LitespaceAddBufnr(a:bufnr)
endfunction

function! litespace#removeBufnr(bufnr)
  call s:LitespaceRemoveBufnr(a:bufnr)
endfunction

function! litespace#tabline()
  return s:LitespaceTabLine()
endfunction

function! litespace#displayAllBufferList()
  call s:ListWindowDisplayAllBufferList()
endfunction

function! litespace#displayTabBufferList()
  call s:ListWindowDisplayTabBufferList()
endfunction

function! litespace#displayTabList()
  " call s:TabListWindowDisplay(winnr())
  call s:TabListPromptGoto()
endfunction

function! litespace#tabRename()
  let l:bufferList = s:BufferListFromCurrentTab()
  call inputsave()
  let l:tabname = input('Rename tab: ', '')
  call inputrestore()
  let l:bufferList.tabname = l:tabname
  redraw!
endfunction

function! litespace#promptLoadSpaces()
  call s:LitespacePromptLoadSpaces()
endfunction

function! litespace#promptLoadSpace()
  call s:LitespacePromptLoadSpace()
endfunction

function! litespace#promptLoadTabSpace()
  call s:LitespacePromptLoadTabSpace()
endfunction

function! litespace#promptEditSpace()
  call s:LitespacePromptEditSpace()
endfunction

function! litespace#promptAppendToSpace()
  call s:LitespacePromptAppendToSpace()
endfunction

function! litespace#bufferListToggleFrozen(bufferList)
  call s:bufferListToggleFrozen(a:bufferList)
endfunction

function! litespace#getAllBufferList()
  return s:LitespaceGetAllBufferList()
endfunction

function! litespace#getCurrentTabBufferList()
  return s:BufferListFromCurrentTab()
endfunction

