set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set autoindent			" always set autoindenting on
set history=50			" keep 50 lines of command line history
set ruler			" show the cursor position all the time
set showcmd			" display incomplete commands
set incsearch			" do incremental searching
set background=dark
set showmatch 
set ignorecase
set smartcase
set hidden			" don't tell me to save a buffer before when I
set smartindent
set autoindent
set expandtab

set laststatus=2


" want to move out of it.

set printexpr=PrintFile(v:fname_in)
function PrintFile(fname)
	call system("lp " . a:fname)
	call delete(a:fname)
	return v:shell_error
endfunc

set fileencoding=utf-8
set encoding=utf-8

let	g:showmarks_enable=0	" Disable showmarks by default - toggle with F4.

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
	syntax on
	set hlsearch
	"set tabstop=4
endif

if $t_Co > 2
	set background dark
	colors darkblue
endif	

" Theme setting:
if has("gui_running")
	colorscheme biogoo	
	set guifont=Lucida\ Console\ Semi-Condensed\ 7.5
	set guioptions=aegim
endif

map #2 :s/\([A-Z]\)\([A-Z][A-Z]*\)/\1\L\2/g<CR>
map #3 :Tlist<CR>
map #4 :ShowMarksToggle<CR>



" Number truncation:
map <silent> ,,t  :. rubydo $_.gsub!(/(\d+\.\d+)/) { sprintf("%.*f", 2, $1.to_f) } <CR>
map <silent> ,,td :rubydo $_.gsub!(/(\d+\.\d+)/) { sprintf("%.*f", 2, $1.to_f) } <CR>

" Create a skeleton m file using the function prototype that is the current
" line.
map #5 :execute MatSkell()<CR>
function MatSkell()
	let s:line = getline(".")
	let s:output = system("matlabSkell.rb \'" . s:line . "\'")
	:execute ":e " . s:output
endfunction

"--------------------------------------------------
" " Mappings for XMP ruby evaluation.
" " See
" " http://eigenclass.org/hiki.rb?Enhanced+xmp+code+evaluation+and+annotation
" map <silent> #9 !xmp.rb ruby<cr>
" nmap <silent> #9 V<F9>
" imap <silent> #9 <ESC><F9>a
"-------------------------------------------------- 


" Switch off the arrow keys :-)
"--------------------------------------------------
" :nnoremap <Up> <Nop>
" :nnoremap <Down> <Nop>
" :nnoremap <Left> <Nop>
" :nnoremap <Right> <Nop>
"-------------------------------------------------- 

" make return clean the current search hilight.
:nnoremap <silent> <CR> :noh<CR>

"Spelling - you need vimspell for this.
set infercase

let spell_auto_type="none"

if has("autocmd")
	filetype plugin indent on
	" Filetype overrides. 
	"see header files as 'c' header, instead of cpp.
	au BufRead,BufNewFile *.h	setfiletype c
        autocmd Filetype c setlocal shiftwidth=4 shiftround
	"and make sure html files shiftwdith is 2.
	autocmd FileType *html setlocal shiftwidth=2
	autocmd FileType *xml setlocal shiftwidth=2
	autocmd FileType matlab setlocal shiftwidth=2
	autocmd FileType ruby setlocal shiftwidth=2
	au! BufRead,BufNewFile *.otl		setfiletype vo_base
	au! BufRead,BufNewFile *.oln		setfiletype xoutliner
        autocmd BufRead,BufNewFile *.py set ai
	" When editing a file, always jump to the last known cursor position.
	" Don't do it when the position is invalid or when inside an event
	" handler (happens when dropping a file on gvim).
	autocmd BufReadPost *
				\ if line("'\"") > 0 && line("'\"") <= line("$") |
				\   exe "normal g`\"" |
				\ endif
endif " has("autocmd")

if has("autocmd") && exists("+omnifunc")
	autocmd Filetype *
				\	if &omnifunc == "" |
				\		setlocal omnifunc=syntaxcomplete#Complete |
				\	endif
endif



set runtimepath=~/.vim,$VIMRUNTIME
