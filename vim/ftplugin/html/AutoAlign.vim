" AutoAlign: ftplugin support for HTML
" Author:    Charles E. Campbell, Jr.
" Date:      Sep 19, 2006
" Version:   12
" ---------------------------------------------------------------------
let b:loaded_autoalign_html= "v12"

"  overloading '>' to keep things lined up {{{1
ino <silent> > ><c-o>:silent call AutoAlign(-1)<cr>
let b:autoalign_reqdpat1 = '</[tT][rR]>$'
let b:autoalign_notpat1  = '\%(</[tT][rR]>\)\@!.\{5}$'
let b:autoalign_suspend1 = '\c</\=table>'
if !exists("g:mapleader")
 let b:autoalign_cmd1     = 'norm \Htd$'
else
 let b:autoalign_cmd1     = "norm ".g:mapleader."\Htd$"
endif
