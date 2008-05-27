" Viki.vim -- A pseudo mini-wiki minor mode for Vim
" @Author:      Thomas Link (samul AT web.de)
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     08-Dec-2003.
" @Last Change: 05-Feb-2005.
" @Revision: 1.6.1.4
"
" vimscript #861
"
" Short Description:
" This plugin adds wiki-like hypertext capabilities to any document. Just type 
" :VikiMinorMode and all wiki names will be highlighted. If you press <c-cr> 
" when the cursor is over a wiki name, you jump to (or create) the referred 
" page. When invoked as :VikiMode or via :set ft=viki additional highlighting 
" is provided.
"
" Requirements:
" - multvals.vim (vimscript #171, >= 3.6.2, 13-Sep-2004)
" 
" Optional Enhancements:
" - genutils.vim (vimscript #197 for saving back references)
" - imaps.vim (vimscript #244 or #475 for |:VimQuote|)
" - kpsewhich (not a vim plugin :-) for vikiLaTeX
"
" Change Log: (See bottom of file)
" 

if &cp || exists("loaded_viki") "{{{2
    finish
endif
if !exists("loaded_multvals") || loaded_multvals < 308
    echoerr "Viki.vim requires multvals.vim >= 308"
    finish
endif
let loaded_viki = 105

let g:vikiDefNil  = ''
let g:vikiDefSep  = "\n"

let s:vikiSelfEsc = '\'
let g:vikiSelfRef = '.'

if !exists("tlist_viki_settings") "{{{2
    let tlist_viki_settings="deplate;s:structure"
endif

if !exists("g:vikiLowerCharacters") "{{{2
    let g:vikiLowerCharacters = "a-z"
endif

if !exists("g:vikiUpperCharacters") "{{{2
    let g:vikiUpperCharacters = "A-Z"
endif

if !exists("g:vikiSpecialProtocols") "{{{2
    let g:vikiSpecialProtocols = 'https\?\|ftps\?\|nntp\|mailto\|mailbox'
endif

if !exists("g:vikiSpecialProtocolsExceptions") "{{{2
    let g:vikiSpecialProtocolsExceptions = ""
endif

if !exists("g:vikiSpecialFiles") "{{{2
    " try to put image suffixes first
    let g:vikiSpecialFiles = 'jpg\|gif\|bmp\|eps\|png\|jpeg\|wmf\|pdf\|ps\|dvi'
endif

if !exists("g:vikiSpecialFilesExceptions") "{{{2
    let g:vikiSpecialFilesExceptions = ""
endif

if !exists("g:vikiHyperLinkColor")
    if &background == "light"
        let g:vikiHyperLinkColor = "DarkBlue"
    else
        let g:vikiHyperLinkColor = "LightBlue"
    endif
endif

if !exists("g:vikiInexistentColor")
    if &background == "light"
        let g:vikiInexistentColor = "DarkRed"
    else
        let g:vikiInexistentColor = "Red"
    endif
endif

if !exists("g:vikiMapMouse")         | let g:vikiMapMouse = 1           | endif "{{{2
if !exists("g:vikiUseParentSuffix")  | let g:vikiUseParentSuffix = 0    | endif "{{{2
if !exists("g:vikiNameSuffix")       | let g:vikiNameSuffix = ""        | endif "{{{2
if !exists("g:vikiAnchorMarker")     | let g:vikiAnchorMarker = "#"     | endif "{{{2
if !exists("g:vikiFreeMarker")       | let g:vikiFreeMarker = 0         | endif "{{{2
if !exists("g:vikiNameTypes")        | let g:vikiNameTypes = "csSeuix"  | endif "{{{2
if !exists("g:vikiSaveHistory")      | let g:vikiSaveHistory = 0        | endif "{{{2
if !exists("g:vikiExplorer")         | let g:vikiExplorer = "Sexplore"  | endif "{{{2
if !exists("g:vikiMarkInexistent")   | let g:vikiMarkInexistent = 1     | endif "{{{2
if !exists("g:vikiMapInexistent")    | let g:vikiMapInexistent = 1      | endif "{{{2
if !exists("g:vikiMapKeys")          | let g:vikiMapKeys = ").,;:!?\"'" | endif "{{{2
if !exists("g:vikiFamily")           | let g:vikiFamily = ""            | endif "{{{2
if !exists("g:vikiDirSeparator")     | let g:vikiDirSeparator = "/"     | endif "{{{2
if !exists("g:vikiTextstylesVer")    | let g:vikiTextstylesVer = 2      | endif "{{{2

if !exists("g:vikiMapFunctionality") "{{{2
    " f ... follow link
    " i ... check for inexistant
    " q ... quote
    " b ... go back
    let g:vikiMapFunctionality = "fiqb"
endif

if !exists("g:vikiOpenFileWith_ANY") && has("win32") "{{{2
    let g:vikiOpenFileWith_ANY = "silent !cmd /c start %{FILE}"
endif

if !exists("*VikiOpenSpecialFile") "{{{2
    fun! VikiOpenSpecialFile(file) "{{{3
        let proto = tolower(matchstr(a:file, '\c\.\zs[a-z]\+$'))
        let prot  = "g:vikiOpenFileWith_". proto
        let protp = exists(prot)
        if !protp
            let prot  = "g:vikiOpenFileWith_ANY"
            let protp = exists(prot)
        endif
        if protp
            exec 'let openFile = VikiSubstituteArgs('.prot.', "FILE", a:file)'
            exec openFile
        else
            throw "Viki: Please define g:vikiOpenFileWith_". proto ." or g:vikiOpenFileWith_ANY!"
        endif
    endfun
endif

if !exists("g:vikiOpenUrlWith_mailbox") "{{{2
    let g:vikiOpenUrlWith_mailbox="call VikiOpenMailbox('%{URL}')"
    fun! VikiOpenMailbox(url) "{{{3
        exec <SID>DecodeFileUrl(strpart(a:url, 10))
        let idx = matchstr(args, 'number=\zs\d\+$')
        if filereadable(filename)
            call VikiOpenLink(filename, "", 0, "go ".idx)
        else
            throw "Viki: Can't find mailbox url: ".filename
        endif
    endfun
endif

if !exists("g:vikiOpenUrlWith_file") "{{{2
    let g:vikiOpenUrlWith_file="call VikiOpenFileUrl('%{URL}')"
    fun! VikiOpenFileUrl(url) "{{{3
        exec <SID>DecodeFileUrl(strpart(a:url, 6))
        if filereadable(filename)
            call VikiOpenLink(filename, anchor)
        else
            throw "Viki: Can't find file url: ".filename
        endif
    endfun
endif

if !exists("g:vikiOpenUrlWith_ANY")
    if has("win32") "{{{2
        let g:vikiOpenUrlWith_ANY = "silent !rundll32 url.dll,FileProtocolHandler %{URL}"
    endif
endif

if !exists("*VikiOpenSpecialProtocol") "{{{2
    fun! VikiOpenSpecialProtocol(url) "{{{3
        let proto = tolower(matchstr(a:url, '\c^[a-z]\{-}\ze:'))
        let prot  = "g:vikiOpenUrlWith_". proto
        let protp = exists(prot)
        if !protp
            let prot  = "g:vikiOpenUrlWith_ANY"
            let protp = exists(prot)
        endif
        if protp
            exec "let openURL = ". prot
            let openURL = VikiSubstituteArgs(openURL, "URL", a:url)
            exec openURL
        else
            throw "Viki: Please define g:vikiOpenUrlWith_". proto ." or g:vikiOpenUrlWith_ANY!"
        endif
    endfun
endif

let s:InterVikiRx = '^\(['. g:vikiUpperCharacters .']\+\)::\(.\+\)$'

fun! <SID>AddToRegexp(regexp, pattern) "{{{3
    if a:pattern == ""
        return a:regexp
    elseif a:regexp == ""
        return a:pattern
    else
        return a:regexp .'\|'. a:pattern
    endif
endfun

fun! <SID>VikiFindRx() "{{{3
    let rx = <SID>AddToRegexp("", b:vikiSimpleNameSimpleRx)
    let rx = <SID>AddToRegexp(rx, b:vikiExtendedNameSimpleRx)
    let rx = <SID>AddToRegexp(rx, b:vikiUrlSimpleRx)
    return rx
endf

fun! VikiFind(flag) "{{{3
    let rx = <SID>VikiFindRx()
    if rx != ""
        call search(rx, a:flag)
    endif
endfun

command! VikiFindNext call VikiDispatchOnFamily("VikiFind", "")
command! VikiFindPrev call VikiDispatchOnFamily("VikiFind", "b")

fun! <SID>IsSupportedType(type)
    return stridx(b:vikiNameTypes, a:type) >= 0 
endf

fun! <SID>VikiRxFromCollection(coll)
    " let rx = strpart(a:coll, 0, strlen(a:coll) - 1)
    " let rx = substitute(rx, "\n", '\\|', "g")
    let rx = substitute(a:coll, '\\|$', '', "")
    if rx == ""
        return ""
    else
        return '\V\('. rx .'\)'
    endif
endf

" VikiMarkInexistent(line1, line2, maxcol, quick)
" maxcol ... check only up to maxcol
" quick  ... check only if the cursor is located after a link
fun! <SID>VikiMarkInexistent(line1, line2, ...)
    let li0 = line(".")
    let co0 = virtcol(".")
    let li  = li0
    let co  = col(".")
    if a:0 >= 2 && a:2 && !(synIDattr(synID(li, co - 1, 1), "name") =~ '^viki.*Link$')
        return
    endif

    let maxcol = a:0 >= 1 ? (a:1 == -1 ? 9999999 : a:1) : 9999999
    
    if a:line1 > 0
        exe "norm! ". a:line1 ."G"
        let min = a:line1
    else
        go
        let min = 1
    endif
    let max = a:line2 > 0 ? a:line2 : line("$")

    if line(".") == 1 && line("$") == max
        let b:vikiNamesNull = ""
        let b:vikiNamesOk   = ""
    else
        if !exists("b:vikiNamesNull") | let b:vikiNamesNull = "" | endif
        if !exists("b:vikiNamesOk")   | let b:vikiNamesOk   = "" | endif
    endif

    try
        let feedback = (max - min) > 5
        if feedback
            let sl  = &statusline
            let rng = min ."-". max
            let &statusline="Viki: checking line ". rng
            let rng = " (". min ."-". max .")"
            redrawstatus
        endif

        if line(".") == 1
            norm! G$
        else
            norm! k$
        endif

        let rx = <SID>VikiFindRx()
        let t  = search(rx, "w")
        let pp = 0
        let ll = 0
        while t >= min && t <= max && col(".") < maxcol
            if feedback
                let li = line(".")
                if li % 10 == 0 && li != ll
                    let &statusline="Viki: checking line ". line(".") . rng
                    redrawstatus
                    let ll = li
                endif
            endif
            let def = VikiGetLink("-", 1)
            if def == "-"
                echom "Internal error: VikiMarkInexistent: ". def
            else
                let dest = MvElementAt(def, g:vikiDefSep, 1)
                let part = MvElementAt(def, g:vikiDefSep, 3)
                if part =~ "^". b:vikiSimpleNameSimpleRx ."$"
                    let check = 1
                    if part =~ '^\[-.*-\]$'
                        let partx = escape(part, "'\"\\/")
                    else
                        let partx = '\<'. escape(part, "'\"\\/") .'\>'
                    endif
                elseif dest =~ "^". b:vikiUrlSimpleRx ."$"
                    let check = 0
                    let partx = escape(part, "'\"\\/")
                    let b:vikiNamesNull = MvRemoveElementAll(b:vikiNamesNull, '\\|', partx, '\|')
                    let b:vikiNamesOk   = MvPushToFront(b:vikiNamesOk, '\\|', partx, '\|')
                elseif part =~ b:vikiExtendedNameSimpleRx
                    let check = 1
                    let partx = escape(part, "'\"\\/")
                    " elseif part =~ b:vikiCmdSimpleRx
                    " <+TBD+>
                else
                    let check = 0
                endif
                if check && dest != "" && dest != g:vikiSelfRef && !isdirectory(dest)
                    if filereadable(dest)
                        " let b:vikiNamesNull = MvRemoveElementAll(b:vikiNamesNull, "\n", partx)
                        " let b:vikiNamesOk   = MvPushToFront(b:vikiNamesOk, "\n", partx)
                        let b:vikiNamesNull = MvRemoveElementAll(b:vikiNamesNull, '\\|', partx, '\|')
                        let b:vikiNamesOk   = MvPushToFront(b:vikiNamesOk, '\\|', partx, '\|')
                    else
                        " let b:vikiNamesNull = MvPushToFront(b:vikiNamesNull, "\n", partx)
                        " let b:vikiNamesOk   = MvRemoveElementAll(b:vikiNamesOk, "\n", partx)
                        let b:vikiNamesNull = MvPushToFront(b:vikiNamesNull, '\\|', partx, '\|')
                        let b:vikiNamesOk   = MvRemoveElementAll(b:vikiNamesOk, '\\|', partx, '\|')
                    endif
                endif
            endif
            let t = search(rx, "W")
        endwh
        if b:vikiMarkInexistent == 1
            exe 'syntax clear '. b:vikiInexistentHighlight
            let rx = <SID>VikiRxFromCollection(b:vikiNamesNull)
            " call inputdialog("DBG: ". maxcol ." ". rx)
            if rx != ""
                exe 'syntax match '. b:vikiInexistentHighlight .' /'. rx .'/'
            endif
        elseif  b:vikiMarkInexistent == 2
            syntax clear vikiOkLink
            syntax clear vikiExtendedOkLink
            let rx = <SID>VikiRxFromCollection(b:vikiNamesOk)
            if rx != ""
                exe 'syntax match vikiOkLink /'. rx .'/'
            endif
        endif
    finally
        if feedback
            let &statusline=sl
        endif
    endtry
    exe "norm! ". li0 ."G". co0 ."|"
    let b:vikiCheckInexistent = 0
endfun

command! -nargs=* -range=% VikiMarkInexistent call <SID>VikiMarkInexistent(<line1>, <line2>, <f-args>)
command! VikiMarkInexistentInParagraph '{,'}VikiMarkInexistent
command! VikiMarkInexistentInParagraphQuick exec "'{,'}VikiMarkInexistent -1 1"
command! VikiMarkInexistentInLine .,.VikiMarkInexistent
command! VikiMarkInexistentInLineQuick exec ".,.VikiMarkInexistent ". col(".") ." 1"

fun! VikiCheckInexistent()
    if &ft == "viki" && g:vikiMarkInexistent && exists("b:vikiCheckInexistent") && b:vikiCheckInexistent > 0
        " echom "DBG VikiCheckInexistent() co=". virtcol(".") ." li=". line(".") ." b:vikiCheckInexistent=".b:vikiCheckInexistent 
        call <SID>VikiMarkInexistent(b:vikiCheckInexistent, b:vikiCheckInexistent)
        " VikiMarkInexistent
        " VikiMarkInexistentInParagraph
    endif
endfun

autocmd BufWinEnter * call VikiCheckInexistent()

fun! VikiSetBufferVar(name, ...) "{{{3
    if !exists("b:".a:name)
        if a:0 > 0
            let i = 1
            while i <= a:0
                exe "let altVar = a:". i
                if altVar[0] == "*"
                    exe "let b:".a:name." = ". strpart(altVar, 1)
                    return
                elseif exists(altVar)
                    exe "let b:".a:name." = ". altVar
                    return
                endif
                let i = i + 1
            endwh
            throw "VikiSetBuffer: Couldn't set ". a:name
        else
            exe "let b:".a:name." = g:".a:name
        endif
    endif
endfun

fun! <SID>VikiLetVar(name, var) "{{{3
    if exists("b:".a:var)
        return "let ".a:name." = b:".a:var
    elseif exists("g:".a:var)
        return "let ".a:name." = g:".a:var
    else
        return ""
    endif
endfun

fun! VikiDispatchOnFamily(fn, ...) "{{{3
    let fam = exists("b:vikiFamily") ? b:vikiFamily : g:vikiFamily
    if fam == "" || !exists("*".a:fn.fam)
        let cmd = a:fn
    else
        let cmd = a:fn.fam
    endif
    
    let i = 1
    let args = ""
    while i <= a:0
        exe "let val = 'a:".i."'"
        if i == 1
            let args = args . val
        else
            let args = args . ", " val
        endif
        let i = i + 1
    endwh
    exe "return ". cmd . "(" . args . ")"
endfun

fun! VikiSetupBuffer(state, ...) "{{{3
    let dontSetup = a:0 > 0 ? a:1 : ""
    " let noMatch = '\%0l' "match nothing
    let noMatch = ""
   
    if exists("b:vikiNoSimpleNames") && b:vikiNoSimpleNames
        let b:vikiNameTypes = substitute(b:vikiNameTypes, '\Cs', '', 'g')
    endif

    call VikiSetBufferVar("vikiAnchorMarker")
    call VikiSetBufferVar("vikiSpecialProtocols")
    call VikiSetBufferVar("vikiSpecialProtocolsExceptions")
    call VikiSetBufferVar("vikiMarkInexistent")
    call VikiSetBufferVar("vikiTextstylesVer")

    if a:state =~ '1$'
        call VikiSetBufferVar("vikiCommentStart", 
                    \ "b:commentStart", "b:ECcommentOpen", "b:EnhCommentifyCommentOpen",
                    \ "*matchstr(&commentstring, '^\\zs.*\\ze%s')")
        call VikiSetBufferVar("vikiCommentEnd",
                    \ "b:commentEnd", "b:ECcommentClose", "b:EnhCommentifyCommentClose", 
                    \ "*matchstr(&commentstring, '%s\\zs.*\\ze$')")
    endif
    
    let b:vikiSimpleNameQuoteChars = '^][:*/&?<>|\"'
    
    let b:vikiSimpleNameQuoteBeg   = '\[-'
    let b:vikiSimpleNameQuoteEnd   = '-\]'
    let b:vikiQuotedSelfRef        = "^". b:vikiSimpleNameQuoteBeg . b:vikiSimpleNameQuoteEnd ."$"
    let b:vikiQuotedRef            = "^". b:vikiSimpleNameQuoteBeg .'.\+'. b:vikiSimpleNameQuoteEnd ."$"

    let b:vikiAnchorNameRx         = '['. g:vikiLowerCharacters .']['. 
                \ g:vikiLowerCharacters . g:vikiUpperCharacters .'_0-9]\+'
    
    if b:vikiNameTypes =~? "s" && !(dontSetup =~? "s")
        if b:vikiNameTypes =~# "S" && !(dontSetup =~# "S")
            let quotedVikiName = b:vikiSimpleNameQuoteBeg 
                        \ .'['. b:vikiSimpleNameQuoteChars .']'
                        \ .'\{-}'. b:vikiSimpleNameQuoteEnd
        else
            let quotedVikiName = ""
        endif
        if b:vikiNameTypes =~# "s" && !(dontSetup =~# "s")
            let simpleWikiName = '\<['. g:vikiUpperCharacters .']['. g:vikiLowerCharacters
                        \ .']\+\(['. g:vikiUpperCharacters.']['.g:vikiLowerCharacters
                        \ .'0-9]\+\)\+\>'
            if quotedVikiName != ""
                let quotedVikiName = quotedVikiName .'\|'
            endif
        else
            let simpleWikiName = ""
        endif
        let b:vikiSimpleNameRx = '\C\(\(\<['. g:vikiUpperCharacters .']\+::\)\?'
                    \ .'\('. quotedVikiName . simpleWikiName .'\)\)'
                    \ .'\(#\('. b:vikiAnchorNameRx .'\)\>\)\?'
        let b:vikiSimpleNameSimpleRx = '\C\(\<['.g:vikiUpperCharacters.']\+::\)\?'
                    \ .'\('. quotedVikiName . simpleWikiName .'\)'
                    \ .'\(#'. b:vikiAnchorNameRx .'\>\)\?'
        let b:vikiSimpleNameNameIdx   = 1
        let b:vikiSimpleNameDestIdx   = 0
        let b:vikiSimpleNameAnchorIdx = 6
        let b:vikiSimpleNameCompound = 'let erx="'. escape(b:vikiSimpleNameRx, '\"')
                    \ .'" | let nameIdx='. b:vikiSimpleNameNameIdx
                    \ .' | let destIdx='. b:vikiSimpleNameDestIdx
                    \ .' | let anchorIdx='. b:vikiSimpleNameAnchorIdx
    else
        let b:vikiSimpleNameRx        = noMatch
        let b:vikiSimpleNameSimpleRx  = noMatch
        let b:vikiSimpleNameNameIdx   = 0
        let b:vikiSimpleNameDestIdx   = 0
        let b:vikiSimpleNameAnchorIdx = 0
    endif
   
    if b:vikiNameTypes =~# "u" && !(dontSetup =~# "u")
        let urlChars = 'A-Za-z0-9.:%?=&_~@$/|-'
        let b:vikiUrlRx = '\<\(\('.b:vikiSpecialProtocols.'\):['. urlChars .']\+\)'.
                    \ '\(#\([A-Za-z0-9]\+\)\>\)\?'
        let b:vikiUrlSimpleRx = '\<\('. b:vikiSpecialProtocols .'\):['. urlChars .']\+'.
                    \ '\(#[A-Za-z0-9]\+\>\)\?'
        let b:vikiUrlNameIdx   = 0
        let b:vikiUrlDestIdx   = 1
        let b:vikiUrlAnchorIdx = 4
        let b:vikiUrlCompound = 'let erx="'. escape(b:vikiUrlRx, '\"')
                    \ .'" | let nameIdx='. b:vikiUrlNameIdx
                    \ .' | let destIdx='. b:vikiUrlDestIdx
                    \ .' | let anchorIdx='. b:vikiUrlAnchorIdx
    else
        let b:vikiUrlRx        = noMatch
        let b:vikiUrlSimpleRx  = noMatch
        let b:vikiUrlNameIdx   = 0
        let b:vikiUrlDestIdx   = 0
        let b:vikiUrlAnchorIdx = 0
    endif
   
    if b:vikiNameTypes =~# "x" && !(dontSetup =~# "x")
        let b:vikiCmdRx        = '\({\S\+\|#['. g:vikiUpperCharacters .']\w*\)\(.\{-}\):\s*\(.\{-}\)\($\|}\)'
        let b:vikiCmdSimpleRx  = '\({\S\+\|#['. g:vikiUpperCharacters .']\w*\).\{-}\($\|}\)'
        let b:vikiCmdNameIdx   = 1
        let b:vikiCmdDestIdx   = 3
        let b:vikiCmdAnchorIdx = 2
        let b:vikiCmdCompound = 'let erx="'. escape(b:vikiCmdRx, '\"')
                    \ .'" | let nameIdx='. b:vikiCmdNameIdx
                    \ .' | let destIdx='. b:vikiCmdDestIdx
                    \ .' | let anchorIdx='. b:vikiCmdAnchorIdx
    else
        let b:vikiCmdRx        = noMatch
        let b:vikiCmdSimpleRx  = noMatch
        let b:vikiCmdNameIdx   = 0
        let b:vikiCmdDestIdx   = 0
        let b:vikiCmdAnchorIdx = 0
    endif
    
    if b:vikiNameTypes =~# "e" && !(dontSetup =~# "e")
        let b:vikiExtendedNameRx = '\[\[\(\('.b:vikiSpecialProtocols.'\)://[^]]\+\|[^]#]\+\)\?'.
                    \ '\(#\('. b:vikiAnchorNameRx .'\)\)\?\]\(\[\([^]]\+\)\]\)\?[!~\-]*\]'
        let b:vikiExtendedNameSimpleRx = '\[\[\('. b:vikiSpecialProtocols .'://[^]]\+\|[^]#]\+\)\?'.
                    \ '\(#'. b:vikiAnchorNameRx .'\)\?\]\(\[[^]]\+\]\)\?[!~\-]*\]'
        let b:vikiExtendedNameNameIdx   = 6
        let b:vikiExtendedNameDestIdx   = 1
        let b:vikiExtendedNameAnchorIdx = 4
        let b:vikiExtendedNameCompound = 'let erx="'. escape(b:vikiExtendedNameRx, '\"')
                    \ .'" | let nameIdx='. b:vikiExtendedNameNameIdx
                    \ .' | let destIdx='. b:vikiExtendedNameDestIdx
                    \ .' | let anchorIdx='. b:vikiExtendedNameAnchorIdx
    else
        let b:vikiExtendedNameRx        = noMatch
        let b:vikiExtendedNameSimpleRx  = noMatch
        let b:vikiExtendedNameNameIdx   = 0
        let b:vikiExtendedNameDestIdx   = 0
        let b:vikiExtendedNameAnchorIdx = 0
    endif

    let b:vikiInexistentHighlight = "vikiInexistentLink"
endfun

fun! VikiDefineMarkup(state) "{{{3
    if b:vikiNameTypes =~? "s" && b:vikiSimpleNameRx != ""
        exe "syntax match vikiLink /" . b:vikiSimpleNameRx . "/"
    endif
    if b:vikiNameTypes =~# "e" && b:vikiExtendedNameRx != ""
        exe "syntax match vikiExtendedLink '" . b:vikiExtendedNameRx . "'"
    endif
    if b:vikiNameTypes =~# "u" && b:vikiUrlRx != ""
        exe "syntax match vikiURL /" . b:vikiUrlRx . "/"
    endif
endfun

fun! VikiDefineHighlighting(state) "{{{3
    if version < 508
        command! -nargs=+ VikiHiLink hi link <args>
    else
        command! -nargs=+ VikiHiLink hi def link <args>
    endif

    exe "hi vikiInexistentLink term=bold,underline cterm=bold,underline gui=bold,underline". 
                \ " ctermbg=". g:vikiInexistentColor ." guifg=". g:vikiInexistentColor
    exe "hi vikiHyperLink term=bold,underline cterm=bold,underline gui=bold,underline". 
                \ " ctermbg=". g:vikiHyperLinkColor ." guifg=". g:vikiHyperLinkColor

    if b:vikiNameTypes =~? "s"
        VikiHiLink vikiLink vikiHyperLink
        VikiHiLink vikiOkLink vikiHyperLink
        VikiHiLink vikiRevLink Normal
    endif
    if b:vikiNameTypes =~# "e"
        VikiHiLink vikiExtendedLink vikiHyperLink
        VikiHiLink vikiExtendedOkLink vikiHyperLink
        VikiHiLink vikiRevExtendedLink Normal
    endif
    if b:vikiNameTypes =~# "u"
        VikiHiLink vikiURL vikiHyperLink
    endif
    delcommand VikiHiLink
endfun

fun! <SID>MapMarkInexistent(key, element, insert, before)
    let arg = maparg(a:key, "i")
    if arg == ""
        let arg = a:insert
    endif
    if a:before
        exe 'inoremap <silent> <buffer> '. a:key .' '. arg .'<c-o>:VikiMarkInexistentIn'. a:element .'<cr>'
    else
        exe 'inoremap <silent> <buffer> '. a:key .' <c-o>:VikiMarkInexistentIn'. a:element .'<cr>'. arg
    endif
endf

fun! VikiMapKeys(state)
    if exists("b:vikiMapFunctionality") && b:vikiMapFunctionality
        let mf = b:vikiMapFunctionality
    else
        let mf = g:vikiMapFunctionality
    endif
    if mf =~ 'f' && !hasmapto("VikiMaybeFollowLink")
        "nnoremap <buffer> <c-cr> "=VikiMaybeFollowLink("",1)<cr>p
        "inoremap <buffer> <c-cr> <c-r>=VikiMaybeFollowLink("",1)<cr>
        "nmap <buffer> <c-cr> "=VikiMaybeFollowLink(1,1)<cr>p
        "imap <buffer> <c-cr> <c-r>=VikiMaybeFollowLink(1,1)<cr>
        "exe "nnoremap <buffer> <c-cr> \"=VikiMaybeFollowLink(\"".maparg("<c-cr>")."\",1)<cr>p"
        "exe "inoremap <buffer> <c-cr> <c-r>=VikiMaybeFollowLink(\"".maparg("<c-cr>", "i")."\",1)<cr>"
        "nnoremap <buffer> <c-cr> "=VikiMaybeFollowLink(0)<cr>p
        "inoremap <buffer> <c-cr> <c-r>=VikiMaybeFollowLink(0)<cr>
        nnoremap <buffer> <silent> <c-cr> :call VikiMaybeFollowLink(0,1)<cr>
        inoremap <buffer> <silent> <c-cr> <c-o>:call VikiMaybeFollowLink(0,1)<cr>
        nnoremap <buffer> <silent> <LocalLeader><c-cr> :call VikiMaybeFollowLink(0,1,-1)<cr>
        nnoremap <buffer> <silent> <LocalLeader>vs :call VikiMaybeFollowLink(0,1,-1)<cr>
        nnoremap <buffer> <silent> <LocalLeader>vv :call VikiMaybeFollowLink(0,1,-2)<cr>
        nnoremap <buffer> <silent> <LocalLeader>v1 :call VikiMaybeFollowLink(0,1,1)<cr>
        nnoremap <buffer> <silent> <LocalLeader>v2 :call VikiMaybeFollowLink(0,1,2)<cr>
        nnoremap <buffer> <silent> <LocalLeader>v3 :call VikiMaybeFollowLink(0,1,3)<cr>
        nnoremap <buffer> <silent> <LocalLeader>v4 :call VikiMaybeFollowLink(0,1,4)<cr>
        if g:vikiMapMouse
            nnoremap <buffer> <silent> <m-leftmouse> <leftmouse>:call VikiMaybeFollowLink(0,1)<cr>
            inoremap <buffer> <silent> <m-leftmouse> <leftmouse><c-o>:call VikiMaybeFollowLink(0,1)<cr>
        endif
        "nnoremap <buffer> <s-c-cr> :call VikiMaybeFollowLink(0,1)<cr>
        "inoremap <buffer> <s-c-cr> <c-o><c-cr>
    endif
    if mf =~ 'i' && !hasmapto("VikiMarkInexistent")
        noremap <buffer> <silent> <LocalLeader>vd :VikiMarkInexistent<cr>
        noremap <buffer> <silent> <LocalLeader>vp :VikiMarkInexistentInParagraph<cr>
        if g:vikiMapInexistent
            let i = 0
            let m = strlen(g:vikiMapKeys)
            while i < m
                let k = g:vikiMapKeys[i]
                call <SID>MapMarkInexistent(k, "LineQuick", k, 0)
                let i = i + 1
            endwh
            call <SID>MapMarkInexistent("]", "LineQuick", "]", 1)
            call <SID>MapMarkInexistent("<space>", "LineQuick", " ", 0)
            call <SID>MapMarkInexistent("<cr>", "LineQuick", "", 0)
            " call <SID>MapMarkInexistent("<cr>", "Paragraph", "", 0)
        endif
    endif
    if mf =~ 'q' && !hasmapto("VikiQuote") && exists("*VEnclose")
        vnoremap <buffer> <silent> <LocalLeader>vq :VikiQuote<cr><esc>:VikiMarkInexistentInLineQuick<cr>
        nnoremap <buffer> <silent> <LocalLeader>vq viw:VikiQuote<cr><esc>:VikiMarkInexistentInLineQuick<cr>
    endif
    if mf =~ 'b' && !hasmapto("VikiGoBack")
        nnoremap <buffer> <silent> <LocalLeader>vb :call VikiGoBack()<cr>
        if g:vikiMapMouse
            nnoremap <buffer> <silent> <m-rightmouse> <leftmouse>:call VikiGoBack(0)<cr>
            inoremap <buffer> <silent> <m-rightmouse> <leftmouse><c-o>:call VikiGoBack(0)<cr>
        endif
    endif
endf

"state ... 0,  +/-1, +/-2
fun! VikiMinorMode(state) "{{{3
    if exists("b:vikiEnabled") && b:vikiEnabled
        if a:state == 0
            throw "Viki can't be disabled (not yet)."
        else
            return 0
        endif
    elseif a:state
        " c ... CamelCase 
        " s ... Simple viki name 
        " S ... Simple quoted viki name
        " e ... Extended viki name
        " u ... URL
        " i ... InterViki
        " call VikiSetBufferVar("vikiNameTypes", "g:vikiNameTypes", "*'csSeui'")
        call VikiSetBufferVar("vikiNameTypes")

        call VikiDispatchOnFamily("VikiSetupBuffer", a:state)
        call VikiDispatchOnFamily("VikiDefineMarkup", a:state)
        call VikiDispatchOnFamily("VikiDefineHighlighting", a:state)
        call VikiDispatchOnFamily("VikiMapKeys", a:state)

        let b:vikiEnabled = 1
        return 1
    endif
endfun

command! VikiMinorMode call VikiMinorMode(1)
command! VikiMinorModeMaybe call VikiMinorMode(-1)
" this requires imaps to be installed
command! -range VikiQuote :call VEnclose("[-", "-]", "[-", "-]")

fun! VikiMode(state) "{{{3
    if exists("b:vikiEnabled")
        if a:state == 0
            throw "Viki can't be disabled (not yet)."
        else
            return 0
        endif
    elseif a:state
        set filetype=viki
    endif
endfun

command! VikiMode call VikiMode(2)
command! VikiModeMaybe call VikiMode(-2)

fun! <SID>AddVarToMultVal(var, val) "{{{3
    if exists(a:var)
        exe "let i = MvIndexOfElement(". a:var .", '". g:vikiDefSep ."', ". a:val .")"
        exe "let ". a:var ."=MvPushToFront(". a:var .", '". g:vikiDefSep ."', ". a:val .")"
        return i
    else
        exe "let ". a:var ."=MvAddElement('', '". g:vikiDefSep ."', ". a:val .")"
        return -1
    endif
endfun

fun! VikiIsInRegion(line)
    let i   = 0
    let max = col("$")
    while i < max
        if synIDattr(synID(a:line, i, 1), "name") == "vikiRegion"
            return 1
        endif
        let i = i + 1
    endw
    return 0
endfun

fun! <SID>VikiSetBackRef(file, li, co) "{{{3
    let i = <SID>AddVarToMultVal("b:VikiBackFile", "'". a:file ."'")
    if i >= 0
        let b:VikiBackLine = MvPushToFrontElementAt(b:VikiBackLine, g:vikiDefSep, i)
        let b:VikiBackCol  = MvPushToFrontElementAt(b:VikiBackCol,  g:vikiDefSep, i)
    else
        call <SID>AddVarToMultVal("b:VikiBackLine", a:li)
        call <SID>AddVarToMultVal("b:VikiBackCol",  a:co)
    endif
endfun

fun! VikiSelect(array, seperator, queryString) "{{{3
    let n = MvNumberOfElements(a:array, a:seperator)
    if n == 1
        return 0
    elseif n > 1
        let i  = 0
        let nn = 0
        while i <= n
            let f = MvElementAt(a:array, a:seperator, i)
            if f != ""
                if i == 0
                    echomsg i ."* ". f
                else
                    echomsg i ."  ". f
                endif
                let nn = i
            endif
            let i = i + 1
        endwh
        if nn == 0
            let this = 0
        else
            let this = input(a:queryString ." [0-".nn."]: ", "0")
        endif
        if  this >= 0 && this <= nn
            return this
        endif
    endif
    return -1
endfun

fun! <SID>VikiSelectThisBackRef(n) "{{{3
    return "let vbf = '". MvElementAt(b:VikiBackFile, g:vikiDefSep, a:n) ."'".
                \ " | let vbl = ". MvElementAt(b:VikiBackLine, g:vikiDefSep, a:n) .
                \ " | let vbc = ". MvElementAt(b:VikiBackCol, g:vikiDefSep, a:n)
endfun

fun! <SID>VikiSelectBackRef(...) "{{{3
    if exists("b:VikiBackFile") && exists("b:VikiBackLine") && exists("b:VikiBackCol")
        if a:0 >= 1 && a:1 >= 0
            let s = a:1
        else
            let s = VikiSelect(b:VikiBackFile, g:vikiDefSep, "Select Back Reference")
        endif
        if s >= 0
            return <SID>VikiSelectThisBackRef(s)
        endif
    endif
    return ""
endfun

if g:vikiSaveHistory && exists("*GetPersistentVar") && exists("*PutPersistentVar") "{{{2
    fun! VikiGetSimplifiedBufferName() "{{{3
        return substitute( expand("%:p"), "[^a-zA-Z0-9]", "_", "g")
    endfun
    
    fun! VikiSaveBackReferences() "{{{3
        if exists("b:VikiBackFile") && b:VikiBackFile != ""
            call PutPersistentVar("VikiBackFile", VikiGetSimplifiedBufferName(), b:VikiBackFile)
            call PutPersistentVar("VikiBackLine", VikiGetSimplifiedBufferName(), b:VikiBackLine)
            call PutPersistentVar("VikiBackCol",  VikiGetSimplifiedBufferName(), b:VikiBackCol)
        endif
    endfun
    
    fun! VikiRestoreBackReferences() "{{{3
        if exists("b:vikiEnabled") && !exists("b:VikiBackFile")
            let b:VikiBackFile = GetPersistentVar("VikiBackFile", VikiGetSimplifiedBufferName(), "")
            let b:VikiBackLine = GetPersistentVar("VikiBackLine", VikiGetSimplifiedBufferName(), "")
            let b:VikiBackCol  = GetPersistentVar("VikiBackCol",  VikiGetSimplifiedBufferName(), "")
        endif
    endfun

    au BufEnter * call VikiRestoreBackReferences()
    au BufLeave * call VikiSaveBackReferences()
endif

fun! VikiGoBack(...) "{{{3
    let s  = (a:0 >= 1) ? a:1 : -1
    let br = <SID>VikiSelectBackRef(s)
    if br == ""
        echomsg "Viki: No back reference defined? (". s ."/". br .")"
    else
        exe br
        let buf = bufnr("^". vbf ."$")
        if buf >= 0
            exe "buffer ".buf
        else
            exe "edit " . vbf
        endif
        if vbf == expand("%:p")
            call cursor(vbl, vbc)
        else
            throw "Viki: Couldn't open file: ". b:VikiBackFile
        endif
    endif
endfun

fun! VikiSubstituteArgs(str, ...) "{{{3
    let i  = 1
    let rv = escape(a:str, '\')
    while a:0 >= i
        exec "let lab = a:". i
        exec "let val = a:". (i+1)
        let rv = substitute(rv, '\C\(^\|[^%]\)\zs%{'. lab .'}', escape(val, '\'), "g")
        let rv = escape(rv, '\')
        let i = i + 2
    endwh
    let rv = substitute(rv, '%%', "%", "g")
    return rv
endfun

fun! VikiFindAnchor(anchor) "{{{3
    if a:anchor != g:vikiDefNil
        let co = virtcol(".")
        let li = line(".")
        let anchorRx = '\^'. b:vikiCommentStart .'\?'. b:vikiAnchorMarker . a:anchor
        if exists("b:vikiAnchorRx")
            let varx = VikiSubstituteArgs(b:vikiAnchorRx, 'ANCHOR', a:anchor)
            let anchorRx = '\('.anchorRx.'\|'. varx .'\)'
        endif
        norm! $
        let found = search('\V'. anchorRx, "w")
        if !found
            exec "norm! ". li ."G". co ."|"
            if g:vikiFreeMarker
                call search('\c\V'. escape(a:anchor, '\'), "w")
            endif
        endif
    endif
endfun

fun! VikiOpenLink(filename, anchor, ...) "{{{3
    let create  = a:0 >= 1 ? a:1 : 0
    let postcmd = a:0 >= 2 ? a:2 : ""
    let winNr   = a:0 >= 3 ? a:3 : 0
    
    if winNr == 0
        if exists("b:vikiSplit")
            let winNr = b:vikiSplit
        elseif exists("g:vikiSplit")
            let winNr = g:vikiSplit
        else
            let winNr = 0
        endif
    endif

    let li = line(".")
    let co = col(".")
    let fi = expand("%:p")
    
    " let buf = bufnr("^". simplify(a:filename) ."$")
    let buf = bufnr("^". a:filename ."$")
    " let buf = bufnr(a:filename)
    if winNr != 0
        let wm = <SID>HowManyWindows()
        if winNr == -2
            wincmd v
        elseif wm == 1 || winNr == -1
            wincmd s
        else
            " if winNr == -1
                " let wc = winnr()
                " if wc < wm
                    " let winNr = wc + 1
                " else
                    " let winNr = wc - 1
                " endif
            " endif
            exec winNr ."wincmd w"
        end
    endif
    if buf >= 0
        exe "buffer ".buf
        call <SID>VikiSetBackRef(fi, li, co)
        call VikiDispatchOnFamily("VikiMinorMode", -1)
        call VikiDispatchOnFamily("VikiFindAnchor", a:anchor)
    elseif create && exists("b:createVikiPage")
        exe b:createVikiPage . " " . a:filename
    elseif exists("b:editVikiPage")
        exe b:editVikiPage . " " . a:filename
    else
        exe "edit " . a:filename
        set buflisted
        call <SID>VikiSetBackRef(fi, li, co)
        call VikiDispatchOnFamily("VikiMinorMode", -1)
        call VikiDispatchOnFamily("VikiFindAnchor", a:anchor)
    endif
    if postcmd != ""
        exec postcmd
    endif
endfun

fun! <SID>HowManyWindows()
    let i = 1
    while winbufnr(i) > 0
        let i = i + 1
    endwh
    return i - 1
endf

fun! <SID>DecodeFileUrl(dest) "{{{3
    let dest = substitute(a:dest, '^\c/*\([a-z]\)|', '\1:', "")
    let rv = ""
    let i  = 0
    while 1
        let in = match(dest, '%\d\d', i)
        if in >= 0
            let c  = "0x".strpart(dest, in + 1, 2)
            let rv = rv. strpart(dest, i, in - i) . nr2char(c)
            let i  = in + 3
        else
            break
        endif
    endwh
    let rv     = rv. strpart(dest, i)
    let uend   = match(rv, '[?#]')
    if uend >= 0
        let args   = matchstr(rv, '?\zs.\+$', uend)
        let anchor = matchstr(rv, '#\zs.\+$', uend)
        let rv     = strpart(rv, 0, uend)
    else
        let args   = ""
        let anchor = ""
        let rv     = rv
    end
    return "let filename='". rv ."'|let anchor='". anchor ."'|let args='". args ."'"
endfun

fun! <SID>GetSpecialFilesSuffixes() "{{{3
    if exists("b:vikiSpecialFiles")
        return b:vikiSpecialFiles .'\|'. g:vikiSpecialFiles
    else
        return g:vikiSpecialFiles
    endif
endf

fun! <SID>VikiFollowLink(def, ...) "{{{3
    let winNr  = a:0 >= 1 ? a:1 : 0
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    let anchor = MvElementAt(a:def, g:vikiDefSep, 2)
    if name == g:vikiSelfRef || dest == g:vikiSelfRef
        call VikiDispatchOnFamily("VikiFindAnchor", anchor)
    elseif dest == g:vikiDefNil
		throw "No target? ".a:def
    else
        if dest =~ '^\('.b:vikiSpecialProtocols.'\):' &&
                    \ (b:vikiSpecialProtocolsExceptions == "" ||
                    \ !(dest =~ b:vikiSpecialProtocolsExceptions))
            call VikiOpenSpecialProtocol(dest)
        else
            let vikiSpecialFiles = <SID>GetSpecialFilesSuffixes()
            if dest =~ '\.\('. vikiSpecialFiles .'\)$' &&
                        \ (g:vikiSpecialFilesExceptions == "" ||
                        \ !(dest =~ g:vikiSpecialFilesExceptions))
                call VikiOpenSpecialFile(dest)
            elseif filereadable(dest)                 "reference to a local, already existing file
                call VikiOpenLink(dest, anchor, 0, "", winNr)
            elseif bufexists(dest)
                exec "buffer ". dest
            elseif isdirectory(dest)
                exe g:vikiExplorer ." ". dest
            else
                let ok = input("File doesn't exists. Create '".dest."'? (Y/n) ", "y")
                if ok != "" && ok != "n"
                    let b:vikiCheckInexistent = line(".")
                    call VikiOpenLink(dest, anchor, 1)
                endif
            endif
        endif
    endif
    return ""
endfun

fun! <SID>MakeVikiDefPart(txt) "{{{3
    if a:txt == ""
        return g:vikiDefNil
    else
        return a:txt
    endif
endfun

fun! VikiMakeDef(name, dest, anchor, part) "{{{3
    if a:name =~ g:vikiDefSep || a:dest =~ g:vikiDefSep || a:anchor =~ g:vikiDefSep 
                \ || a:part =~ g:vikiDefSep
        throw "Viki: A viki definition must not include ".g:vikiDefSep
                    \ .": ".a:name.", ".a:dest.", ".a:anchor ." (". a:part .")"
    else
        let arr = MvAddElement("",  g:vikiDefSep, <SID>MakeVikiDefPart(a:name))
        let arr = MvAddElement(arr, g:vikiDefSep, <SID>MakeVikiDefPart(a:dest))
        let arr = MvAddElement(arr, g:vikiDefSep, <SID>MakeVikiDefPart(a:anchor))
        let arr = MvAddElement(arr, g:vikiDefSep, <SID>MakeVikiDefPart(a:part))
        return arr
    endif
endfun

fun! <SID>GetVikiNamePart(txt, erx, idx, errorMsg) "{{{3
    if a:idx
        let rv = substitute(a:txt, '^\C'. a:erx ."$", '\'.a:idx, "")
        if rv == ""
            return g:vikiDefNil
        else
            return rv
        endif
    else
        return g:vikiDefNil
    endif
endfun

fun! VikiLinkDefinition(txt, col, compound, ignoreSyntax) "{{{3
    exe a:compound
    if erx != ""
        let ebeg = -1
        let cont = match(a:txt, erx, 0)
        while (0 <= cont) && (cont <= a:col)
            let contn = matchend(a:txt, erx, cont)
            if (cont <= a:col) && (a:col < contn)
                let ebeg = match(a:txt, erx, cont)
                let elen = contn - ebeg
                break
            else
                let cont = match(a:txt, erx, contn)
            endif
        endwh
        if ebeg >= 0
            let part   = strpart(a:txt, ebeg, elen)
            let name   = <SID>GetVikiNamePart(part, erx, nameIdx,   "no name")
            let dest   = <SID>GetVikiNamePart(part, erx, destIdx,   "no destination")
            let anchor = <SID>GetVikiNamePart(part, erx, anchorIdx, "no anchor")
            return VikiMakeDef(name, dest, anchor, part)
        elseif a:ignoreSyntax
            return ""
        else
            throw "Viki: Malformed viki name: " . a:txt . " (". erx .")"
        endif
    else
        return ""
    endif
endfun

fun! <SID>VikiGetSuffix() "{{{3
    if exists("b:vikiNameSuffix")
        return b:vikiNameSuffix
    endif
    if g:vikiUseParentSuffix
        let sfx = expand("%:e")
        if sfx != ""
            return ".".sfx
        endif
    endif
    return g:vikiNameSuffix
endfun

fun! VikiExpandSimpleName(dest, name, suffix) "{{{3
    if a:suffix == g:vikiDefSep
        return a:dest . g:vikiDirSeparator . a:name . <SID>VikiGetSuffix()
    else
        return a:dest . g:vikiDirSeparator . a:name . (a:suffix == g:vikiDefSep? "" : a:suffix)
    endif
endfun

fun! VikiCompleteSimpleNameDef(def) "{{{3
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    if name == g:vikiDefNil
        throw "Viki: Malformed simple viki name (no name): ".a:def
    endif

    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    if !(dest == g:vikiDefNil)
        throw "Viki: Malformed simple viki name (destination=".dest."): ". a:def
    endif
    
    let useSuffix = g:vikiDefSep
    if b:vikiNameTypes =~# "i" && name =~# s:InterVikiRx
        let ow = substitute(name, s:InterVikiRx, '\1', "")
        exec <SID>VikiLetVar("dest", "vikiInter".ow)
        if exists("dest")
            let dest = expand(dest)
            let name = substitute(name, s:InterVikiRx, '\2', "")
            exec <SID>VikiLetVar("useSuffix", "vikiInter".ow."_suffix")
        else
            throw "Viki: InterViki is not defined: ".ow
        endif
    else
        let dest = expand("%:p:h")
    endif

    if b:vikiNameTypes =~# "S"
        if name =~ b:vikiQuotedSelfRef
            let name  = g:vikiSelfRef
        elseif name =~ b:vikiQuotedRef
            let name = matchstr(name, "^". b:vikiSimpleNameQuoteBeg .'\zs.\+\ze'. b:vikiSimpleNameQuoteEnd ."$")
        endif
    elseif !(b:vikiNameTypes =~# "c")
        throw "Viki: CamelCase names not allowed"
    endif
    
    if name != g:vikiSelfRef
        let rdest = VikiExpandSimpleName(dest, name, useSuffix)
    else
        let rdest = g:vikiDefNil
    endif
    let anchor = MvElementAt(a:def, g:vikiDefSep, 2)
    let part   = MvElementAt(a:def, g:vikiDefSep, 3)
    return VikiMakeDef(name, rdest, anchor, part)
endfun

fun! VikiCompleteExtendedNameDef(def) "{{{3
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    let anchor = MvElementAt(a:def, g:vikiDefSep, 2)
    let part   = MvElementAt(a:def, g:vikiDefSep, 3)
    if dest == g:vikiDefNil
        if anchor == g:vikiDefNil
            throw "Viki: Malformed extended viki name (no destination): ".a:def
        else
            let dest = g:vikiSelfRef
        endif
    elseif dest =~? '^[a-z]:'                      " an absolute dos path
    elseif dest =~? '^\/'                          " an absolute unix path
    elseif dest =~? '^'.b:vikiSpecialProtocols.':' " some protocol
    elseif dest =~ '^\~'                           " user home
        let dest = $HOME . strpart(dest, 1)
    else                                           " a relative path
        let dest = expand("%:p:h") .g:vikiDirSeparator. dest
    endif
    if name == g:vikiDefNil
        let name = dest
    endif
    if dest != g:vikiSelfRef && fnamemodify(dest, ":p:h") == expand("%:p:h")
        if fnamemodify(dest, ":e") == ""
            let dest = dest.<SID>VikiGetSuffix()
        endif
    endif
    return VikiMakeDef(name, dest, anchor, part)
endfun
 
fun! <SID>FindFileWithSuffix(filename, suffixes) "{{{3
    if filereadable(a:filename)
        return a:filename
    else
        let suffixes = a:suffixes
        while 1
            let elt = MvElementAt(suffixes, '\\|', 0)
            if elt != ""
                let fn = a:filename .".". elt
                if filereadable(fn)
                    return fn
                else
                    let suffixes = MvRemoveElement(suffixes, '\\|', elt)
                endif
            else
                return g:vikiDefNil
            endif
        endwh
    endif
    return g:vikiDefNil
endf

fun! VikiCompleteCmdDef(def) "{{{3
    let name   = MvElementAt(a:def, g:vikiDefSep, 0)
    let dest   = MvElementAt(a:def, g:vikiDefSep, 1)
    let args   = MvElementAt(a:def, g:vikiDefSep, 2)
    let part   = MvElementAt(a:def, g:vikiDefSep, 3)
    let anchor = g:vikiDefNil
    if name ==# "#IMG" || name =~# "{img"
        let vikiSpecialFiles = <SID>GetSpecialFilesSuffixes()
        let dest = <SID>FindFileWithSuffix(dest, vikiSpecialFiles)
    elseif name ==# "#Img"
        let id = matchstr(args, '\sid=\zs\w\+')
        if id != ""
            let vikiSpecialFiles = <SID>GetSpecialFilesSuffixes()
            let dest = <SID>FindFileWithSuffix(id, vikiSpecialFiles)
        endif
    elseif name =~ "^#INC"
        " <+TBD+> Search path?
    else
        " throw "Viki: Unknown command: ". name
        let name = g:vikiDefNil
        let dest = g:vikiDefNil
        let anchor = g:vikiDefNil
    endif
    return VikiMakeDef(name, dest, anchor, part)
endf

fun! <SID>VikiLinkNotFoundEtc(oldmap, ignoreSyntax) "{{{3
    if a:oldmap == ""
        echomsg "Viki: Show me the way to the next viki name or I have to ... ".a:ignoreSyntax.":".getline(".")
    elseif a:oldmap == 1
        return "\<c-cr>"
    else
        return a:oldmap
    endif
endfun

" VikiGetLink(oldmap, ignoreSyntax, ?col, ?txt)
fun! VikiGetLink(oldmap, ignoreSyntax, ...) "{{{3
    let synName = synIDattr(synID(line('.'),col('.'),0),"name")
    if synName ==# "vikiLink"
        let vikiType = 1
        let tryAll   = 0
    elseif synName ==# "vikiExtendedLink"
        let vikiType = 2
        let tryAll   = 0
    elseif synName ==# "vikiURL"
        let vikiType = 3
        let tryAll   = 0
    elseif synName ==# "vikiCommand" || synName ==# "vikiMacro"
        let vikiType = 4
        let tryAll   = 0
    elseif a:ignoreSyntax
        let vikiType = a:ignoreSyntax
        let tryAll   = 1
    else
        return ""
    endif
    if a:0 >= 1
        let txt = a:1
        let col = a:0 >= 2 ? a:2 : 0
    else
        let txt = getline(".")
        let col = col(".") - 1
    endif
    if (tryAll || vikiType == 1) && stridx(b:vikiNameTypes, "s") >= 0
        if exists("b:getVikiLink")
            exe "let def = " . b:getVikiLink."()"
        else
            let def = VikiLinkDefinition(txt, col, b:vikiSimpleNameCompound, a:ignoreSyntax)
        endif
        if def != ""
            return VikiDispatchOnFamily("VikiCompleteSimpleNameDef", def)
        endif
    endif
    if (tryAll || vikiType == 2) && stridx(b:vikiNameTypes, "e") >= 0
        if exists("b:getExtVikiLink")
            exe "let def = " . b:getExtVikiLink."()"
        else
            let def = VikiLinkDefinition(txt, col, b:vikiExtendedNameCompound, a:ignoreSyntax)
        endif
        if def != ""
            return VikiDispatchOnFamily("VikiCompleteExtendedNameDef", def)
        endif
    endif
    if (tryAll || vikiType == 3) && stridx(b:vikiNameTypes, "u") >= 0
        if exists("b:getURLViki")
            exe "let def = " . b:getURLViki . "()"
        else
            let def = VikiLinkDefinition(txt, col, b:vikiUrlCompound, a:ignoreSyntax)
        endif
        if def != ""
            return VikiDispatchOnFamily("VikiCompleteExtendedNameDef", def)
        endif
    endif
    if (tryAll || vikiType == 4) && stridx(b:vikiNameTypes, "x") >= 0
        if exists("b:getCmdViki")
            exe "let def = " . b:getCmdViki . "()"
        else
            let def = VikiLinkDefinition(txt, col, b:vikiCmdCompound, a:ignoreSyntax)
        endif
        if def != ""
            return VikiDispatchOnFamily("VikiCompleteCmdDef", def)
        endif
    endif
    return ""
endfun

" VikiMaybeFollowLink(oldmap, ignoreSyntax, ?winNr=0)
fun! VikiMaybeFollowLink(oldmap, ignoreSyntax, ...) "{{{3
    let winNr = a:0 >= 1 ? a:1 : 0
    let def = VikiGetLink(a:oldmap, a:ignoreSyntax)
    if def != ""
        return <SID>VikiFollowLink(def, winNr)
    else
        return <SID>VikiLinkNotFoundEtc(a:oldmap, a:ignoreSyntax)
    endif
endfun

fun! VikiEdit(name, ...) "{{{3
    let winNr = a:0 >= 1 ? a:1 : 0
    let ignoreSyntax = 1
    let oldmap = ""
    if !exists("b:vikiNameTypes")
        call VikiSetBufferVar("vikiNameTypes")
        call VikiDispatchOnFamily("VikiSetupBuffer", 0)
    endif
    let def = VikiGetLink(oldmap, ignoreSyntax, a:name)
    if def != ""
        return <SID>VikiFollowLink(def, winNr)
    else
        call <SID>VikiLinkNotFoundEtc(oldmap, ignoreSyntax)
    endif
endfun

command! -nargs=1 VikiEdit :call VikiEdit(<q-args>)


"""" Any Word {{{1
fun! VikiMinorModeAnyWord (state) "{{{3
    let b:vikiFamily = "AnyWord"
    call VikiMinorMode(a:state)
endfun
command! VikiMinorModeAnyWord call VikiMinorModeAnyWord(1)
command! VikiMinorModeMaybeAnyWord call VikiMinorModeAnyWord(-1)

fun! VikiSetupBufferAnyWord(state, ...) "{{{3
    let dontSetup = a:0 > 0 ? a:1 : ""
    call VikiSetupBuffer(a:state, dontSetup)
    if b:vikiNameTypes =~? "s" && !(dontSetup =~? "s")
        if b:vikiNameTypes =~# "S" && !(dontSetup =~# "S")
            let simpleWikiName = b:vikiSimpleNameQuoteBeg
                        \ .'['. b:vikiSimpleNameQuoteChars .']'
                        \ .'\{-}'. b:vikiSimpleNameQuoteEnd
        else
            let simpleWikiName = ""
        endif
        if b:vikiNameTypes =~# "s" && !(dontSetup =~# "s")
            let simple = '\<['. g:vikiUpperCharacters .']['. g:vikiLowerCharacters
                        \ .']\+\(['. g:vikiUpperCharacters.']['.g:vikiLowerCharacters
                        \ .'0-9]\+\)\+\>'
            if simpleWikiName != ""
                let simpleWikiName = simpleWikiName .'\|'. simple
            else
                let simpleWikiName = simple
            endif
        endif
        let anyword = '\<['. b:vikiSimpleNameQuoteChars .' ]\+\>'
        if simpleWikiName != ""
            let simpleWikiName = simpleWikiName .'\|'. anyword
        else
            let simpleWikiName = anyword
        endif
        let b:vikiSimpleNameRx = '\C\(\(\<['. g:vikiUpperCharacters .']\+::\)\?'
                    \ .'\('. simpleWikiName .'\)\)'
                    \ .'\(#\('. b:vikiAnchorNameRx .'\)\>\)\?'
        let b:vikiSimpleNameSimpleRx = '\C\(\<['.g:vikiUpperCharacters.']\+::\)\?'
                    \ .'\('. simpleWikiName .'\)'
                    \ .'\(#'. b:vikiAnchorNameRx .'\>\)\?'
        let b:vikiSimpleNameNameIdx   = 1
        let b:vikiSimpleNameDestIdx   = 0
        let b:vikiSimpleNameAnchorIdx = 6
        let b:vikiSimpleNameCompound = 'let erx="'. escape(b:vikiSimpleNameRx, '\"')
                    \ .'" | let nameIdx='. b:vikiSimpleNameNameIdx
                    \ .' | let destIdx='. b:vikiSimpleNameDestIdx
                    \ .' | let anchorIdx='. b:vikiSimpleNameAnchorIdx
    endif
    let b:vikiInexistentHighlight = "vikiAnyWordInexistentLink"
    let b:vikiMarkInexistent = 2
endf

fun! VikiDefineMarkupAnyWord(state) "{{{3
    if b:vikiNameTypes =~? "s" && b:vikiSimpleNameRx != ""
        exe "syn match vikiRevLink /" . b:vikiSimpleNameRx . "/"
    endif
    if b:vikiNameTypes =~# "e" && b:vikiExtendedNameRx != ""
        exe "syn match vikiRevExtendedLink '" . b:vikiExtendedNameRx . "'"
    endif
    if b:vikiNameTypes =~# "u" && b:vikiUrlRx != ""
        exe "syn match vikiURL /" . b:vikiUrlRx . "/"
    endif
endfun

fun! VikiDefineHighlightingAnyWord(state, ...) "{{{3
    let dontSetup = a:0 > 0 ? a:1 : ""
    call VikiDefineHighlighting(a:state)

    if version < 508
        command! -nargs=+ VikiHiLink hi link <args>
    else
        command! -nargs=+ VikiHiLink hi def link <args>
    endif
    exec "VikiHiLink ". b:vikiInexistentHighlight ." Normal"
    delcommand VikiHiLink
endf

fun! VikiFindAnyWord(flag) "{{{3
    let rx = <SID>VikiRxFromCollection(b:vikiNamesOk)
    if rx != ""
        call search(rx, a:flag)
    endif
endfun


finish "{{{1
_____________________________________________________________________________________

* To Do
- don't know how to deal with viki names that span several lines
- ...


* Change Log
1.6.1
- removed forgotten debug message
- fixed indentation bug

1.6
- b:vikiInverseFold: Inverse folding of subsections
- support for some regions/commands/macros: #INC/#INCLUDE, #IMG, #Img 
(requires an id to be defined), {img}
- g:vikiFreeMarker: Search for the plain anchor text if no explicitly marked 
anchor could be found.
- new command: VikiEdit NAME ... allows editing of arbitrary viki names (also 
understands extended and interviki formats)
- setting the b:vikiNoSimpleNames to true prevents viki from recognizing 
simple viki names
- made some script local functions global so that it should be easier to 
integrate viki with other plugins
- fixed moving cursor on <SID>VikiMarkInexistent()
- fixed typo in b:VikiEnabled, which should be b:vikiEnabled (thanks to Ned 
Konz)

1.5.2
- changed default markup of textstyles: __emphasize__, ''code''; the 
previous markup can be re-enabled by setting g:vikiTextstylesVer to 1)
- fixed problem with VikiQuote
- on follow link check for yet unsaved buffers too

1.5.1
- depends on multvals >= 3.8.0
- new viki family "AnyWord" (see |viki-any-word|), which turns any word into a 
potential viki link
- <LocalLeader>vq, VikiQuote: mark selected text as a quoted viki name 
(requires imaps.vim, vimscript #244 or vimscript #475)
- check for null links when pressing <space>, <cr>, ], and some other keys 
(defined in g:vikiMapKeys)
- a global suffix for viki files can be defined by g:vikiNameSuffix
- fix syntax problem when checking for links to inexistent files

1.5
- distinguish between links to existing and non-existing files
- added key bindings <LL>vs (split) and <LL>vv (split vertically)
- added key bindings <LL>v1 through to <LL>v4: open the viki link 
under cursor in the windows 1 to 4
- handle variables g:vikiSplit, b:vikiSplit
- don't indent regions
- regions can be indented
- When a file doesn't exist, ESC or "n" aborts creation

1.4
- fixed problem with table highlighting that could cause vim to hang
- it is now possible to selectivly disable simple or quoted viki names
- indent plugin

1.3.1
- fixed bug when VikiBack was called without a definitiv back-reference
- fixed problems with latin-1 characters

1.3
- basic ctags support (see |viki-tags|)
- mini-ftplugin for bibtex files (use record labels as anchors)
- added mapping <LocalLeader><c-cr>: follow link in other window (if any)
- disabled the highlighting of italic char styles (i.e., /text/)
- the ftplugin doesn't set deplate as the compiler; renamed the compiler plugin to deplate
- syntax: sync minlines=50
- fix: VikiFoldLevel()

1.2
- syntax file: fix nested regexp problem
- deplate: conversion to html/latex; download from 
http://sourceforge.net/projects/deplate/
- made syntax a little bit more restrictive (*WORD* now matches /\*\w+\*/ 
instead of /\*\S+\*/)
- interviki definitions can now be buffer local variables, too
- fixed <SID>DecodeFileUrl(dest)
- some kind of compiler plugin (uses deplate)
- removed g/b:vikiMarkupEndsWithNewline variable
- saved all files in unix format (thanks to Grant Bowman for the hint)
- removed international characters from g:vikiLowerCharacters and 
g:vikiUpperCharacters because of difficulties with different encodings (thanks 
to Grant Bowman for pointing out this problem); non-english-speaking users have 
to set these variables in their vimrc file

1.1
- g:vikiExplorer (for viewing directories)
- preliminary support for "soft" anchors (b:vikiAnchorRx)
- improved VikiOpenSpecialProtocol(url); g:vikiOpenUrlWith_{PROTOCOL}, 
g:vikiOpenUrlWith_ANY
- improved VikiOpenSpecialFile(file); g:vikiOpenFileWith_{SUFFIX}, 
g:vikiOpenFileWith_ANY
- anchors may contain upper characters (but must begin with a lower char)
- some support for Mozilla ThunderBird mailbox-URLs (this requires spaces to 
be encoded as %20)
- changed g:vikiDefSep to '‡‡‡'

1.0
- Extended names: For compatibility reasons with other wikis, the anchor is 
now in the reference part.
- For compatibility reasons with other wikis, prepending an anchor with 
b:commentStart is optional.
- g:vikiUseParentSuffix
- Renamed variables & functions (basically s/Wiki/Viki/g)
- added a ftplugin stub, moved the description to a help file
- "[--]" is reference to current file
- Folding support (at section level)
- Intervikis
- More highlighting
- g:vikiFamily, b:vikiFamily
- VikiGoBack() (persistent history data)
- rudimentary LaTeX support ("soft" viki names)

" vim: ff=unix
