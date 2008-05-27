" AutoAlign: ftplugin support for bib
" Author:    Charles E. Campbell, Jr.
" Date:      Sep 19, 2006
" Version:   12
" ---------------------------------------------------------------------
let b:loaded_autoalign_bib= "v12"
"call Decho("loaded ftplugin/bib/AutoAlign!")

"  overloading '=' to keep things lined up {{{1
ino <silent> = =<c-o>:silent call AutoAlign(1)<cr>
let b:autoalign_reqdpat1= '^\(\s*\h\w*\(\[\d\+]\)\{0,}\(->\|\.\)\=\)\+\s*[-+*/^|%]\=='
let b:autoalign_notpat1 = '^[^=]\+$'
if !exists("g:mapleader")
 let b:autoalign_cmd1    = 'norm \t=$'
else
 let b:autoalign_cmd1    = "norm ".g:mapleader."t=$"
endif
