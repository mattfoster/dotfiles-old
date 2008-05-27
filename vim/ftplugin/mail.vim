" Email mappings: as borrowed from: charles.maunch.name

" Nuke nested levels of quotations
map ,nq :%g/^>>/d

" Clear Empty Lines
map ,cel :%s/^\s\+$//e
map ,cqoq :%s/^>\s\+/> /e

" remove all > On blah... stuff left behind in quoted text - huggie
nmap ,cqmh :g/^\([>*] \)\+On.*wrote:$/d

" Clear blank lines after my On foo wrote: 
map ,db /^On.*wrote:$/e

" Kill more than 1 empty quoted lines
nmap ,ceql :g/^\(>\)\{2,}\s*$/d
nmap ,cqel :%s/^> \s*$//

" Kill power quote - change wierd "> blah>" to >>
nmap ,kpq :s/^> *[a-zA-Z]*>/>>/e

" kill space runs (3 or more spaces become 2 space)
nmap ,ksr :%s/   \+/  /g

" remove quoted sig
map ,rq /^> *-- 

"function DelSig()
"    let modified=&#038;modified
"    let lnum = line(".")
"    let cnum = col(".")
"    normal! H
"    let scrtop = line(".")
"    normal! G
"    execute '?-- $?,$d'
"    call cursor( scrtop, 0 )
"    normal! zt
"    call cursor( lnum, cnum )
"    if modified == 0
"        set nomodified
"    endif
"endfun

nnoremap ,ds :silent call DelSig()

"    ,Sl = "squeeze lines"
"    Turn all blocks of empty lines (within current visual)
"    into *one* empty line:
map ,dl :g/^$/,/./-j

" Condense multiple Re:'s
" map ,re 1G/^Subject:\ns/\(Re: \)\+/Re: /e\n
map ,re call MailCondenseRe()

" Sven's wondeful change subject macro
map ,cs 1G/^Subject: \nyypIX-Old-<esc>-W
vmap ,qp    :s/^/> /\n

" Rotate Signatures (because...)
:nmap ,rggs mQG:?^-- $<cr>:nohl<cr>o<esc>dG:r !~/bin/signature.rb<cr>`Q

" Clean the Email Function
function! CleanEmail()
  " Remove empty quoted lines
  normal ,ceql
  " Remove the empty lines after an unquoted On blah stuff
  normal ,db
  " Clear empty lines and turn into space to write in
  normal ,cqel
  " Remove blocks of empty lines
  normal ,dl
  " Remove quoted On blah stuff
  normal ,cqmh
  " Remove many Re:'s from the Subject line
  normal ,re
endfun

function! Fixflowed()
   " save position
   let l = line(".")
   let c = col(".")
   normal G$
   " whiles are used to avoid nasty error messages
   " add spaces to the end of every line
   while search('\([^]> :]\)\n\(>[> ]*[^> ]\)','w') > 0
      s/\([^]> :]\)\n\(>[> ]*[^> ]\)/\1 \r\2/g
   endwhile
   " now, fix the wockas spacing from the text
   while search('^\([> ]*>\)\([^> ]\)','w') > 0
      s/^\([> ]*>\)\([^> ]\)/\1 \2/
   endwhile
   " now, compress the wockas
   while search('^\(>>*\) \(>>*\( [^>]\)*\)', 'w') > 0
      s/^\(>>*\) \(>>*\( [^>]\)*\)/\1\2/
   endwhile
   " restore the original location, such as it is
   execute l . " normal " . c . "|"
endfun

"set list
"set listchars=trail:_,tab:>.
set expandtab
set textwidth=75
set comments=s1:/*,mb:*,ex:*/,://,b:#,:%,:XCOMM,n:>,fb:- 
set noshowmatch
"set ft=headers
syn on

" Autoflow paragraphs you edit as you type, no more gq!
"set fo=aw2t

silent call Fixflowed()
silent call CleanEmail()


