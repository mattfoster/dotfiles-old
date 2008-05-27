" viki.vim -- viki indentation
" @Author:      Thomas Link (samul AT web.de)
" @Website:     http://members.a1.net/t.link/
" @License:     GPL (see http://www.gnu.org/licenses/gpl.txt)
" @Created:     16-Jän-2004.
" @Last Change: 05-Feb-2005.
" @Revision: 0.189

if exists("b:did_indent") || exists("g:vikiNoIndent")
    finish
endif
let b:did_indent = 1

setlocal indentexpr=VikiGetIndent()
setlocal indentkeys&
setlocal indentkeys=0=#\ ,0=?\ ,0=<*>\ ,0=-\ ,0=+\ ,0=@\ ,=::\ ,!^F,o,O,e
" setlocal indentkeys=0=#<space>,0=?<space>,0=<*><space>,0=-<space>,=::<space>,!^F,o,O,e

" Only define the function once.
if exists("*VikiGetIndent")
    finish
endif

fun! VikiGetIndent()
    " Find a non-blank line above the current line.
    let lnum = prevnonblank(v:lnum - 1)

    " At the start of the file use zero indent.
    if lnum == 0
        return 0
    endif

    let ind  = indent(lnum)
    let line = getline(lnum)      " last line
    
    let cnum  = v:lnum
    let cind  = indent(cnum)
    
    " Do not change indentation in regions
    if VikiIsInRegion(cnum)
        return cind
    endif
    
    let pnum   = v:lnum - 1
    let pind   = indent(pnum)
    
    let pline  = getline(pnum) " last line
    let plCont = matchend(pline, '\\$')
    
    if plCont >= 0
        let plHeading = matchend(pline, '^\*\+\s\+')
        if plHeading >= 0
            " echo "DBG continuation plHeading=". plHeading
            return plHeading
        else
            " echo "DBG continuation pind=". pind
            return pind
        endif
    end
    
    if cind > 0
        let listRx = '^\s\+\([-+*#?@]\|[0-9#]\+\.\|[a-zA-Z?]\.\)\s'
        let descRx = '^\s\+.\{-1,}\s::\s'
        
        let cline = getline(cnum) " current line
        
        " Do not change indentation of:
        "   - commented lines
        "   - headings
        if cline =~ '^\(\s*%\|\*\)'
            " echom "DBG comment or heading: ". cline
            return ind
        endif


        let clList = matchend(cline, listRx)
        let clDesc = matchend(cline, descRx)
        let cln    = clList >= 0 ? clList : clDesc

        if clList >= 0 || clDesc >= 0
            let spaceEnd = matchend(cline, '^\s\+')
            let rv = (spaceEnd / &sw) * &sw
            " echom "DBG clList=". clList ." clDesc=". clDesc
            return rv
        else
            let plList = matchend(pline, listRx)
            " echom "DBG plList=". plList ." plDesc=". plDesc
            if plList >= 0
                " echom "DBG plList ". plList ." ". pline
                return plList
            endif

            let plDesc = matchend(pline, descRx)
            if plDesc >= 0
                " echom "DBG plDesc ". pind + (&sw / 2)
                return pind + (&sw / 2)
            endif

            if cind < ind
                let rv = (cind / &sw) * &sw
                " echom "DBG cind < ind ". rv
                return rv
            elseif cind >= ind
                if cind % &sw == 0
                    " echom "DBG cind % &sw ". cind
                    return cind
                else
                    " echom "DBG cind >= ind ". ind
                    return ind
                end
            endif
        endif
    endif

    " echom "DBG fallback"
    return ind
endfun

