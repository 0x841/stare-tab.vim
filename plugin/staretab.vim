" ------------------------------------------------------------------------------
" staretab.vim
" ------------------------------------------------------------------------------

if exists('g:loaded_staretab')
    finish
endif
let g:loaded_staretab = 1

let s:save_cpo = &cpo
set cpo&vim

if has('windows')
    set tabline=%!staretab#tabline()
endif

let &cpo = s:save_cpo
unlet s:save_cpo

