" Directives for use with: http://github.com/bronson/vim-update-bundles
" BUNDLE: http://github.com/ervandew/screen.git
" BUNDLE: http://github.com/msanders/snipmate.vim.git
" BUNDLE: http://github.com/petdance/vim-perl.git
" BUNDLE: http://github.com/scrooloose/nerdcommenter.git
" BUNDLE: http://github.com/scrooloose/nerdtree.git
" BUNDLE: http://github.com/tpope/vim-fugitive.git
" BUNDLE: http://github.com/tpope/vim-markdown.git
" BUNDLE: http://github.com/tpope/vim-speeddating.git
" BUNDLE: http://github.com/tpope/vim-surround.git
" BUNDLE: http://github.com/vim-scripts/Align.git
" BUNDLE: http://github.com/vim-scripts/AutoAlign.git
" BUNDLE: http://github.com/vim-scripts/Railscasts-Theme-GUIand256color.git

call pathogen#runtime_append_all_bundles() 
call pathogen#helptags() 

set nocompatible

" allow backspacing over everything in insert mode
set backspace=indent,eol,start

set autoindent      " always set autoindenting on
set history=50      " keep 50 lines of command line history
set ruler      " show the cursor position all the time
set showcmd      " display incomplete commands
set incsearch      " do incremental searching
set background=dark
set showmatch 
set ignorecase
set smartcase
set hidden      " don't tell me to save a buffer before when I
set smartindent
set autoindent
set expandtab

set laststatus=2
set fileencoding=utf-8
set encoding=utf-8

let g:showmarks_enable=0 " Disable showmarks by default.

" Switch syntax highlighting on, when the terminal has colors
" Also switch on highlighting the last used search pattern.
if &t_Co > 2 || has("gui_running")
  syntax on
  set hlsearch
endif

if $COLORTERM == 'gnome-terminal' 
  set background=dark
  set term=gnome-256color 
  colorscheme railscasts 
else 
  set background=dark
  colorscheme default 
endif 

" Theme setting:
if has("gui_running")
  " colorscheme biogoo
  colorscheme railscasts
  "set guifont=Lucida\ Console\ Semi-Condensed\ 7.5
  set guifont=Monospace\ 9
  set guioptions=aegim
endif

" Key mappings: 
map #2 :s/\([A-Z]\)\([A-Z][A-Z]*\)/\1\L\2/g<CR>
map #3 :Tlist<CR>
map #4 :ShowMarksToggle<CR>

" Number truncation:
map <silent> ,,t  :. rubydo $_.gsub!(/(\d+\.\d+)/) { sprintf("%.*f", 2, $1.to_f) } <CR>
map <silent> ,,td :rubydo $_.gsub!(/(\d+\.\d+)/) { sprintf("%.*f", 2, $1.to_f) } <CR>

" make return clean the current search hilight.
":nnoremap <silent> <CR> :noh<CR>

" Switch off the arrow keys :-)
" :nnoremap <Up> <Nop>
" :nnoremap <Down> <Nop>
" :nnoremap <Left> <Nop>
" :nnoremap <Right> <Nop>

if has("autocmd")
  filetype plugin indent on
  " Filetype overrides. 
  "see header files as 'c' header, instead of cpp.
  au BufRead,BufNewFile *.h  setfiletype c
  autocmd Filetype c      setlocal shiftwidth=4 shiftround
  "and make sure html files shiftwdith is 2.
  autocmd FileType *html  setlocal shiftwidth=2
  autocmd FileType *xml   setlocal shiftwidth=2
  autocmd FileType matlab setlocal shiftwidth=2
  autocmd FileType ruby   setlocal shiftwidth=2
  autocmd FileType perl   setlocal shiftwidth=4 tabstop=4 softtabstop=4
  au! BufRead,BufNewFile *.otl    setfiletype vo_base
  au! BufRead,BufNewFile *.oln    setfiletype xoutliner
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
    \ if &omnifunc == "" |
    \   setlocal omnifunc=syntaxcomplete#Complete |
    \ endif
endif
