" viki.vim -- the viki ftplugin
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     12-Jän-2004.
" @Last Change: 26-Jän-2005.
" @Revision: 34

if exists("b:did_ftplugin")
  finish
endif
let b:did_ftplugin = 1

let b:vikiCommentStart = "%"
let b:vikiCommentEnd   = ""
if !exists("b:vikiMaxFoldLevel")
    let b:vikiMaxFoldLevel = 5
endif
if !exists("b:vikiInverseFold")
    let b:vikiInverseFold  = 0
endif

exe "setlocal commentstring=". substitute(b:vikiCommentStart, "%", "%%", "g") 
            \ ."%s". substitute(b:vikiCommentEnd, "%", "%%", "g")
exe "setlocal comments=:". b:vikiCommentStart

setlocal foldmethod=expr
setlocal foldexpr=VikiFoldLevel(v:lnum)
setlocal expandtab

fun! VikiFoldLevel(lnum)
    " let head = matchend(getline(a:lnum), '\V\^'. escape(b:vikiHeadingStart, '\') .'\ze\s\+')
    let head = matchend(getline(a:lnum), '\V\^'. b:vikiHeadingStart .'\+\ze\s\+')
    if head > 0
        if b:vikiInverseFold
            if b:vikiMaxFoldLevel > head
                return ">". (b:vikiMaxFoldLevel - head)
            else
                return ">0"
            end
        else
            return ">". head
        endif
    else
        " return foldlevel(a:lnum - 1)
        return "="
    endif
endfun

if !hasmapto(":VikiFind")
    nnoremap <buffer> <c-tab>   :VikiFindNext<cr>
    nnoremap <buffer> <c-s-tab> :VikiFindPrev<cr>
endif

" compiler deplate

let b:vikiEnabled = 2
