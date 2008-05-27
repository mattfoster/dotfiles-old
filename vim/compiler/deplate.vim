" viki.vim
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     25-Apr-2004.
" @Last Change: 07-Nov-2004.
" @Revision:    0.31
" 
" Description:
" Use deplate as the "compiler" for viki files.
" 

let g:current_compiler="deplate"

let s:cpo_save = &cpo
set cpo&vim

fun! DeplateSetCompiler(options)
    if exists("b:deplatePrg")
        exec "setlocal makeprg=".escape(b:deplatePrg ." ". a:options, " ")."\\ $*\\ %"
    elseif exists("g:deplatePrg")
        exec "setlocal makeprg=".escape(g:deplatePrg ." ". a:options, " ")."\\ $*\\ %"
    else
        exec "setlocal makeprg=deplate ".escape(a:options, " ")."\\ $*\\ %"
        " setlocal makeprg=deplate\ $*\ %
    endif
endfun
command! -nargs=* DeplateSetCompiler call DeplateSetCompiler(<q-args>)

DeplateSetCompiler

setlocal errorformat=%f:%l:%m,%f:%l-%*\\d:%m

let &cpo = s:cpo_save
unlet s:cpo_save

" vim: ff=unix
