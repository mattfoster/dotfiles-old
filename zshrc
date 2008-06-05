# History options
HISTFILE=~/.histfile
HISTSIZE=10000 
SAVEHIST=20000 # Bigger for multiple sets of shell history
setopt HIST_IGNORE_DUPS 
setopt HIST_REDUCE_BLANKS
setopt HIST_IGNORE_SPACE

setopt nobeep	# No beeping
# bindkey -v    	# Vi style line editing

# Options
setopt AUTOPUSHD PUSHDMINUS PUSHDSILENT PUSHDTOHOME
setopt AUTOCD			# cd by typing dirname
setopt cdablevars		# Follow variables which are dirnames
setopt interactivecomments	# allow comments on cmd line.
setopt SH_WORD_SPLIT		# split up var in "for x in *"
setopt MULTIOS			# Allow multiple redirection echo 'a'>b>c
setopt CORRECT CORRECT_ALL	# Try to correct command line spelling
setopt BANG_HIST		# Allow ! for accessing history 
setopt NOHUP			# Don't HUP running jobs on logout.
setopt HASH_LIST_ALL
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt EXTENDED_GLOB
setopt HIST_VERIFY 
setopt HIST_APPEND # Append history from multiple shells.
setopt HIST_IGNORE_DUPS
setopt HIST_REDUCE_BLANKS

# fpath=( /sw/share/zsh/Calendar  /sw/share/zsh/Completion  /sw/share/zsh/Exceptions  /sw/share/zsh/MIME /sw/share/zsh/Misc  /sw/share/zsh/Newuser  /sw/share/zsh/Prompts  /sw/share/zsh/TCP  /sw/share/zsh/Zftp  /sw/share/zsh/Zle  /sw/share/zsh/site-functions $fpath)

# Completion
autoload -Uz compinit zmv
compinit

# completion tweaking
zmodload -i zsh/complist
zstyle ':completion:*' use-cache on
zstyle ':completion:*' users resolve
# use dircolours in completion listings
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# allow approximate matching
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric
zstyle ':completion:*' auto-description 'Specify: %d'
zstyle ':completion:*' format 'Completing %d'
zstyle ':completion:*' verbose true
zstyle ':completion:*:functions' ignored-patterns '_*'
zstyle ':completion:*:*:(^rm):*:*files' ignored-patterns \
'*?.(o|c~|zwc)' '*?~'

# only java files for javac
zstyle ':completion:*:javac:*' files '*.java'
# no binary files for vi
zstyle ':completion:*:vi:*' ignored-patterns '*.(o|a|so|aux|dvi|log|swp|fig|bbl|blg|bst|idx|ind|out|toc|class|pdf|ps)'
zstyle ':completion:*:vim:*' ignored-patterns '*.(o|a|so|aux|dvi|log|swp|fig|bbl|blg|bst|idx|ind|out|toc|class|pdf|ps)'
zstyle ':completion:*:gvim:*' ignored-patterns '*.(o|a|so|aux|dvi|log|swp|fig|bbl|blg|bst|idx|ind|out|toc|class|pdf|ps)'
# no binary files for less
zstyle ':completion:*:less:*' ignored-patterns '*.(o|a|so|dvi|fig|out|class|pdf|ps)'
zstyle ':completion:*:zless:*' ignored-patterns '*.(o|a|so|dvi|fig|out|class|pdf|ps)'
# pdf for xpdf
zstyle ':completion:*:xpdf:*' files '*.pdf'
# tar files
zstyle ':completion:*:tar:*' files '*.tar|*.tgz|*.tz|*.tar.Z|*.tar.bz2|*.tZ|*.tar.gz'
# latex to the fullest
# for printing
zstyle ':completion:*:xdvi:*' files '*.dvi'
zstyle ':completion:*:dvips:*' files '*.dvi'

# Group relatex matches:
zstyle ':completion:*' group-name ''
zstyle ':completion:*:-command-:*:(commands|builtins|reserved-words-aliases)' group-name commands
# Separate man page sections
zstyle ':completion:*:manuals' seperate-sections true
# Separate comand line options and descriptions with #
zstyle ':completion:*' list-separator '#'
# Generate descriptions for arguments
zstyle ':completion:*' auto-description 'specify: %d'

# Give long completion options in a list. tab to advance.
zstyle ':completion:*:default' list-prompt '%S%M matches%s'


# Expand out ! when I press space. 
bindkey ' ' magic-space

# if we're on a mac...
if [[ $(uname) == "Darwin" ]]; then
  export EDITOR='mate -w'
  export SVN_EDITOR='mate -w' 
  export CVSEDITOR='mate -w'
	export GNUTERM=aqua # For octave / gnuplot 
	export VIEWER=open
	
	# Fink:
	. /sw/bin/init.sh

fi

for dir in /usr/local/git/bin ~/bin /var/lib/gems/1.8/bin /usr/local/mindi1.0/bin /usr/local/texlive/2007/bin/i386-darwin/ /opt/local/bin /opt/local/sbin; do
        if [[ -x $dir ]]; then
                export PATH=$dir:$PATH
        fi
done

for dir in /usr/local/git/man /sw/share/man; do
        if [[ -x $dir ]]; then
                export MANPATH=$dir:$MANPATH
        fi
done



export DISPLAY=:0.0
autoload colors ; colors

# Load custom config goodness
if [[ -d $HOME/.shrcs ]]; then
        for x in $HOME/.shrcs/*.{z,}rc; do
                source $x
        done
fi
# 
# # export BROWSER='firefox'
# export ZLS_COLORS=$LS_COLORS # ??

fpath=( $HOME/.zsh/func /sw/share/zsh/ $fpath )
export FPATH
export PATH
# Remove duplicate entries
typeset -U fpath path

MANPATH=$MANPATH:/opt/local/man

if [ "$SSH_CONNECTION" != "" ];
then
        # Not running locally...
        local COLOUR='red'
else
        #Running locally...
        local COLOUR='green'
fi

# Set up my prompt.
autoload promptinit && promptinit && prompt doom green $COLOUR

# See From Bash to Z Shell,  Page: 101 
# unalias run-help
autoload -Uz run-help
export HELPDIR='/sw/share/zsh/zsh_help'
alias help=run-help

alias mv='nocorrect mv'
alias rm='nocorrect rm'
alias apt-cache='nocorrect noglob apt-cache'
alias apt-get='nocorrect noglob apt-get'
alias locate='noglob locate'
alias mkdir='nocorrect mkdir'


# # set up some directory variables. 
# export mu=~/music
# export ph=~/photos
# export uni=~/uni
# export src=~/src
# export work=~/work
# export inc=~/incoming
# # : ~mu ~uni ~src ~work ~ph ~inc

# Don't log me out
if [[ "${TERM}" == ([Ex]term*|dtterm|screen*) ]]; then
	unset TMOUT
fi

if [[ $TERM != "DTERM" ]]; then
	autoload zkbd
	[[ ! -d ~/.zkbd ]] && mkdir ~/.zkbd	
	[[ ! -f ~/.zkbd/$TERM-$VENDOR-$OSTYPE ]] && zkbd
	source  ~/.zkbd/$TERM-$VENDOR-$OSTYPE

	# setup key accordingly
	[[ -n ${key[Home]}    ]]  && bindkey  "${key[Home]}"    beginning-of-line
	[[ -n ${key[End]}     ]]  && bindkey  "${key[End]}"     end-of-line
	[[ -n ${key[Insert]}  ]]  && bindkey  "${key[Insert]}"  overwrite-mode
	[[ -n ${key[Delete]}  ]]  && bindkey  "${key[Delete]}"  delete-char
	[[ -n ${key[Up]}      ]]  && bindkey  "${key[Up]}"      up-line-or-history
	[[ -n ${key[Down]}    ]]  && bindkey  "${key[Down]}"    down-line-or-history
	[[ -n ${key[Left]}    ]]  && bindkey  "${key[Left]}"    backward-char
	[[ -n ${key[Right]}   ]]  && bindkey  "${key[Right]}"   forward-char
fi

export LANG=en_GB.UTF-8
# alias gnuplot=/Applications/Gnuplot.app/Contents/Resources/bin/gnuplot
