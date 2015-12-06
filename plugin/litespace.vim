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
" let g:litespace_no_map_default = 0
" let g:litespace_list_style = 0; 1 to hide path

function! LitespaceTabLine()
  return litespace#tabline()
endfunction

" Litespace
augroup Litespace
  autocmd!
  autocmd BufEnter,BufWinEnter * call litespace#addBufnr(expand('<abuf>'))
  " autocmd BufUnload,BufDelete,BufWipeout * call litespace#removeBufnr(expand('<abuf>'))
  autocmd BufUnload * call litespace#removeBufnr(expand('<abuf>'))
  autocmd FileType qf call litespace#removeBufnr(expand('<abuf>'))
augroup END

nnoremap <unique> <silent> <Plug>(litespace_tabnew)                 :tabnew<CR>
nnoremap <unique> <silent> <Plug>(litespace_tabnewlast)             :tablast<CR>:tabnew<CR>
nnoremap <unique> <silent> <Plug>(litespace_tabsplit)               :tab split<CR>
nnoremap <unique> <silent> <Plug>(litespace_tabsplit_horiz)         :tab split<CR>:rightbelow new<CR>:wincmd w<CR>
nnoremap <unique> <silent> <Plug>(litespace_tabsplit_vert)          :tab split<CR>:rightbelow vnew<CR>:wincmd w<CR>
nnoremap <unique> <silent> <Plug>(litespace_window_moveto1)         :call litespace#util#window#moveTo(1)<CR>
nnoremap <unique> <silent> <Plug>(litespace_window_moveto2)         :call litespace#util#window#moveTo(2)<CR>
nnoremap <unique> <silent> <Plug>(litespace_window_moveto3)         :call litespace#util#window#moveTo(3)<CR>
nnoremap <unique> <silent> <Plug>(litespace_window_moveto4)         :call litespace#util#window#moveTo(4)<CR>

nnoremap <unique> <silent> <Plug>(litespace_window_columnonly)      :call litespace#util#column#only()<CR>
nnoremap <unique> <silent> <Plug>(litespace_window_primary_horiz)   :call litespace#util#column#primaryHorizontal()<CR>
nnoremap <unique> <silent> <Plug>(litespace_window_primary_vert)    :call litespace#util#column#primaryVertical()<CR>

nnoremap <unique> <silent> <Plug>(litespace_allbuffers)             :call litespace#displayAllBufferList()<CR>
nnoremap <unique> <silent> <Plug>(litespace_tabbuffers)             :call litespace#displayTabeBufferList()<CR>
nnoremap <unique> <silent> <Plug>(litespace_tablist)                :call litespace#displayTabList()<CR>
nnoremap <unique> <silent> <Plug>(litespace_spaces_load)            :call litespace#promptLoadSpaces()<CR>
nnoremap <unique> <silent> <Plug>(litespace_space_load)             :call litespace#promptLoadSpace()<CR>
nnoremap <unique> <silent> <Plug>(litespace_space_loadtab)          :call litespace#promptLoadTabSpace()<CR>

nnoremap <unique> <silent> <Plug>(litespace_space_edit)             :call litespace#promptEditSpace()<CR>
nnoremap <unique> <silent> <Plug>(litespace_space_append)           :call litespace#promptAppendToSpace()<CR>

nnoremap <unique> <silent> <Plug>(litespace_allbufs_toggle_freeze)  :call litespace#bufferListToggleFrozen(litespace#getAllBufferList())<CR>
nnoremap <unique> <silent> <Plug>(litespace_tabbufs_toggle_freeze)  :call litespace#bufferListToggleFrozen(litespace#getCurrentTabBufferList)<CR>

nmap <unique> <silent> <Leader>tn     <Plug>(litespace_tabnew)
nmap <unique> <silent> <Leader>tN     <Plug>(litespace_tabnewlast)
nmap <unique> <silent> <Leader>wt     <Plug>(litespace_tabsplit)
nmap <unique> <silent> <Leader>ws     <Plug>(litespace_tabsplit_horiz)
nmap <unique> <silent> <Leader>wv     <Plug>(litespace_tabsplit_vert)

nmap <unique> <silent> <Leader>wm1    <Plug>(litespace_window_moveto1)
nmap <unique> <silent> <Leader>wm2    <Plug>(litespace_window_moveto2)
nmap <unique> <silent> <Leader>wm3    <Plug>(litespace_window_moveto3)
nmap <unique> <silent> <Leader>wm4    <Plug>(litespace_window_moveto4)

nmap <unique> <silent> <Leader>wo     <Plug>(litespace_window_columnonly)
nmap <unique> <silent> <Leader>wpk    <Plug>(litespace_window_primary_horiz)
nmap <unique> <silent> <Leader>wph    <Plug>(litespace_window_primary_vert)

if !exists('g:litespace_no_map_default') || !g:litespace_no_map_default
  nmap <unique> <silent> <Leader>lsa    <Plug>(litespace_allbuffers)
  nmap <unique> <silent> <Leader>lss    <Plug>(litespace_tabbuffers)
  nmap <unique> <silent> <Leader>lst    <Plug>(litespace_tablist)
  nmap <unique> <silent> <Leader>ls1    <Plug>(litespace_spaces_load)
  nmap <unique> <silent> <Leader>lso    <Plug>(litespace_space_load)
  nmap <unique> <silent> <Leader>lsO    <Plug>(litespace_space_loadtab)
  nmap <unique> <silent> <Leader>lsp    <Plug>(litespace_space_append)
  nmap <unique> <silent> <Leader>lse    <Plug>(litespace_space_edit)
endif
