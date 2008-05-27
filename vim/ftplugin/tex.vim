"From: http://www.bononia.it/~zack/blog//posts/editing_latex_the_vim_way.html
setlocal tw=80
setlocal ts=8
setlocal sts=1
setlocal sw=1
setlocal iskeyword+=\\
setlocal iskeyword+=:
setlocal makeprg=make
setlocal keywordprg=:help
"setlocal formatoptions+=a
setlocal spell
vmap ,b "zdi\textbf{<C-R>z}<ESC>
vmap ,e "zdi\emph{<C-R>z}<ESC>
vmap ,t "zdi\texttt{<C-R>z}<ESC>

" Latex-Suite
let g:Tex_CompileRule_dvi = 'latex -interaction=nonstopmode -src-specials $*'
if v:servername != ""
	let g:Tex_ViewRule_dvi = 'xdvi -editor "vim --servername ' . v:servername . ' --remote +\%l \%f"'
endif
