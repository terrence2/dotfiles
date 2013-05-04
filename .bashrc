# .bashrc

export HISTSIZE=1000000000
export HISTFILESIZE=1000000000
export HISTCONTROL=ignoredups
shopt -s histappend

# Run clang++ twice when using CCACHE, as it is preprocessor aware.
export CCACHE_CPP2=yes

alias aslron="sudo echo 2 >/proc/sys/kernel/randomize_va_space"
alias aslroff="sudo echo 0 >/proc/sys/kernel/randomize_va_space"
alias swapclear="sudo swapoff; sudo swapon"

alias p=pushd
alias h="history | tac | less"
alias less="less -R"
alias qdiff="hg qdiff --color=always"
alias c="wfm clang"
alias 1="make -j1 -s"
alias 2="make -j2 -s"
alias 3="make -j3 -s"
alias 4="make -j4 -s"
alias 5="make -j5 -s"
alias 6="make -j6 -s"
alias 7="make -j7 -s"
alias 8="make -j8 -s"
alias g="wfm gcc"
alias lsrej="find . -name \"*.rej\""

# Add local to path
export PATH="${PATH}:${HOME}/.local/bin"

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific aliases and functions
function mercurial-qtop() {
    qtop=`hg qtop 2>/dev/null`
    if [ "$qtop" != "" ]; then
        #echo " (+$qtop)"
        HG_QTOP_OUT="($qtop)"
    else
        HG_QTOP_OUT=""
    fi
}

function timer_start {
  timer=${timer:-$SECONDS}
}

function timer_stop {
  TIMER_OUT=$(($SECONDS - $timer))
  unset timer
}

function doprompt {
  timer_stop
  mercurial-qtop
}

trap 'timer_start' DEBUG
PROMPT_COMMAND=doprompt
PS1='\[\033[G\](${TIMER_OUT}s) \[\033[01;34m\]\[\e[1m\]\w \[\033[01;32m\]${HG_QTOP_OUT}\[\033[01;30m\]>\[\e[0m\] '

