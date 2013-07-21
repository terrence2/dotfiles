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

alias less="less -R"
alias lsrej="find . -name \"*.rej\""

# Add local to path
export PATH="${PATH}:${HOME}/.local/bin"

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

function timer_start {
  timer=${timer:-$SECONDS}
}

function timer_stop {
  TIMER_OUT=$(($SECONDS - $timer))
  unset timer
}

function doprompt {
  STATUS_OUT=$?
  timer_stop
}

trap 'timer_start' DEBUG
PROMPT_COMMAND=doprompt
PS1='`prompt ${STATUS_OUT} ${COLUMNS} ${TIMER_OUT}`'
