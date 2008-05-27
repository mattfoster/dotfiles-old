" AutoAlign: ftplugin support for LaTeX
" Author:    Charles E. Campbell, Jr.
" Date:      Sep 19, 2006
" Version:   12
" ---------------------------------------------------------------------
let b:loaded_autoalign_tex = "v12"

"  overloading '\' to keep things lined up {{{1
ino <silent> \\ \\<c-o>:silent call AutoAlign(1)<cr>
let b:autoalign_reqdpat1 = '^\([^&]*&\)\+[^&]*\\\{2}'
let b:autoalign_notpat1  = '^.*\(\\\\\)\@<!$\&^.'
if !exists("g:mapleader")
 let b:autoalign_cmd1     = 'norm \tt$'
else
 let b:autoalign_cmd1     = "norm ".g:mapleader."tt$"
endif
