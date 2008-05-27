" Decho.vim:   Debugging support for VimL
" Last Change: Jul 27, 2004
" Maintainer:  Charles E. Campbell, Jr. PhD <cec@NgrOyphSon.gPsfAc.nMasa.gov>
" Version:     10
"
" Usage:
"   Decho "a string"
"   call Decho("another string")
"   let g:decho_bufname= "ANewDBGBufName"
"   call Decho("one","thing","after","another")
"   DechoOn  : removes any first-column '"' from lines containing Decho
"   DechoOff : inserts a '"' into the first-column in lines containing Decho

" ---------------------------------------------------------------------

" Prevent duplicate loading
if exists("g:loaded_Decho") || &cp
 finish
endif

"  Default Values For Variables:
if !exists("g:decho_bufname")
 let g:decho_bufname= "DBG"
endif
if !exists("s:decho_depth")
 let s:decho_depth  = 0
endif
if !exists("g:decho_winheight")
 let g:decho_winheight= 5
endif
if !exists("g:decho_bufenter")
 let g:decho_bufenter= 0
endif

" ---------------------------------------------------------------------
"  User Interface:
com! -nargs=+ -complete=expression Decho	call Decho(<args>)
com! -nargs=+ -complete=expression Dredir	call Dredir(<args>)
com! -nargs=0 -range=% DechoOn				call DechoOn(<line1>,<line2>)
com! -nargs=0 -range=% DechoOff				call DechoOff(<line1>,<line2>)
com! -nargs=0 Dhide    						call <SID>Dhide(1)
com! -nargs=0 Dshow    						call <SID>Dhide(0)

" ---------------------------------------------------------------------
" Decho: this splits the screen and writes messages to a small
"        window (g:decho_winheight lines) on the bottom of the screen
fun! Decho(...)
 
  let curbuf= bufnr("%")
  if g:decho_bufenter
   let eikeep= &ei
   set ei=BufEnter
  endif

  " As needed, create/switch-to the DBG buffer
  if !bufexists(g:decho_bufname) && bufnr("*/".g:decho_bufname."$") == -1
   " if requested DBG-buffer doesn't exist, create a new one
   " at the bottom of the screen.
   exe "keepjumps silent bot ".g:decho_winheight."new ".g:decho_bufname
   setlocal bt=nofile

  elseif bufwinnr(g:decho_bufname) > 0
   " if requested DBG-buffer exists in a window,
   " go to that window (by window number)
   exe "keepjumps ".bufwinnr(g:decho_bufname)."wincmd W"

  else
   " user must have closed the DBG-buffer window.
   " create a new one at the bottom of the screen.
   exe "keepjumps silent bot ".g:decho_winheight."new"
   setlocal bt=nofile
   exe "keepjumps b ".bufnr(g:decho_bufname)
  endif
  set ft=Decho
  setlocal noswapfile noro nobl

  " Build Message
  let i  = 1
  let msg= ""
  while i <= a:0
   exe "let msg=msg.a:".i
   if i < a:0
    let msg=msg." "
   endif
   let i=i+1
  endwhile

  " Initialize message
  let smsg   = ""
  let idepth = 0
  while idepth < s:decho_depth
   let smsg   = "|".smsg
   let idepth = idepth + 1
  endwhile

  " Handle special characters (\t \r \n)
  let i    = 1
  while msg != ""
   let chr  = strpart(msg,0,1)
   let msg  = strpart(msg,1)
   if char2nr(chr) < 32
   	let smsg = smsg.'^'.nr2char(64+char2nr(chr))
   else
    let smsg = smsg.chr
   endif
  endwhile

  " Write Message to DBG buffer
  setlocal ma
  keepjumps $
  keepjumps let res= append("$",smsg)
  setlocal nomod

  " Put cursor at bottom of DBG window, then return to original window
  exe "res ".g:decho_winheight
  keepjumps norm! G
  if exists("g:decho_hide") && g:decho_hide > 0
   setlocal hidden
   q
  endif
  keepjumps wincmd p

  if g:decho_bufenter
   let &ei= eikeep
  endif
endfun

" ---------------------------------------------------------------------
"  Dfunc: just like Decho, except that it also bumps up the depth
"         It also appends a "{" to facilitate use of %
"         Usage:  call Dfunc("functionname([opt arglist])")
fun! Dfunc(...)
  " Build Message
  let i  = 1
  let msg= ""
  while i <= a:0
   exe "let msg=msg.a:".i
   if i < a:0
    let msg=msg." "
   endif
   let i=i+1
  endwhile
  let msg= msg." {"
  call Decho(msg)
  let s:decho_depth= s:decho_depth + 1
  let s:Dfunclist_{s:decho_depth}= substitute(msg,'[( \t].*$','','')
endfun

" ---------------------------------------------------------------------
"  Dret: just like Decho, except that it also bumps down the depth
"        It also appends a "}" to facilitate use of %
"         Usage:  call Dret("functionname [optional return] [: optional extra info]")
fun! Dret(...)
  " Build Message
  let i  = 1
  let msg= ""
  while i <= a:0
   exe "let msg=msg.a:".i
   if i < a:0
    let msg=msg." "
   endif
   let i=i+1
  endwhile
  let msg= msg." }"
  call Decho("return ".msg)
  if s:decho_depth > 0
   let retfunc= substitute(msg,'\s.*$','','e')
   if  retfunc != s:Dfunclist_{s:decho_depth}
   	echoerr "Dret: appears to be called by<".s:Dfunclist_{s:decho_depth}."> but returning from<".retfunc.">"
   endif
   unlet s:Dfunclist_{s:decho_depth}
   let s:decho_depth= s:decho_depth - 1
  endif
endfun

" ---------------------------------------------------------------------
" DechoOn:
fun! DechoOn(line1,line2)
"  call Dfunc("DechoOn(line1=".a:line1." line2=".a:line2.")")

  call SaveWinPosn()
  exe a:line1.",".a:line2.'g/\<D\%(echo\|func\|redir\|ret\)\>/s/^"\+//'
  call RestoreWinPosn()

"  call Dret("DechoOn")
endfun

" ---------------------------------------------------------------------
" DechoOff:
fun! DechoOff(line1,line2)
"  call Dfunc("DechoOff(line1=".a:line1." line2=".a:line2.")")

  call SaveWinPosn()
  exe a:line1.",".a:line2.'g/\<D\%(echo\|func\|redir\|ret\)\>/s/^[^"]/"&/'
  call RestoreWinPosn()

"  call Dret("DechoOff")
endfun

" ---------------------------------------------------------------------

" DechoDepth: allow user to force depth value
fun! DechoDepth(depth)
  let s:decho_depth= a:depth
endfun

" ---------------------------------------------------------------------
" Dhide: (un)hide DBG buffer
fun! <SID>Dhide(hide)

  if !bufexists(g:decho_bufname) && bufnr("*/".g:decho_bufname."$") == -1
   " DBG-buffer doesn't exist, simply set g:decho_hide
   let g:decho_hide= a:hide

  elseif bufwinnr(g:decho_bufname) > 0
   " DBG-buffer exists in a window, so its not currently hidden
   if a:hide == 0
   	" already visible!
    let g:decho_hide= a:hide
   else
   	" need to hide window.  Goto window and make hidden
	let curwin = winnr()
	let dbgwin = bufwinnr(g:decho_bufname)
    exe bufwinnr(g:decho_bufname)."wincmd W"
	setlocal hidden
	q
	if dbgwin != curwin
	 " return to previous window
     exe curwin."wincmd W"
	endif
   endif

  else
   " The DBG-buffer window is currently hidden.
   if a:hide == 0
	let curwin= winnr()
    exe "silent bot ".g:decho_winheight."new"
    setlocal bh=wipe
    exe "b ".bufnr(g:decho_bufname)
    exe curwin."wincmd W"
   else
   	let g:decho_hide= a:hide
   endif
  endif
  let g:decho_hide= a:hide
endfun

" ---------------------------------------------------------------------
" Dredir: this function performs a debugging redir by temporarily using
"         register a in a redir @a of the given command.  Register a's
"         original contents are restored.
fun! Dredir(cmd)
  " save register a, initialize
  let keep_rega = @a
  let v:errmsg  = ''

  " do the redir of the command to the register a
  try
   redir @a
    exe "keepjumps silent ".a:cmd
  catch /.*/
   let v:errmsg= substitute(v:exception,'^[^:]\+:','','e')
  finally
   redir END
   if v:errmsg == ''
   	let output= @a
   else
   	let output= v:errmsg
   endif
   let @a= keep_rega
  endtry

  " process output via Decho()
  while output != ""
   if output =~ "\n"
   	let redirline = substitute(output,'\n.*$','','e')
   	let output    = substitute(output,'^.\{-}\n\(.*$\)$','\1','e')
   else
   	let redirline = output
   	let output    = ""
   endif
   call Decho("redir<".a:cmd.">: ".redirline)
  endwhile
endfun

" ---------------------------------------------------------------------
