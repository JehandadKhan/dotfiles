# ~/.bashrc: executed by bash(1) for non-login shells.
# see /usr/share/doc/bash/examples/startup-files (in the package bash-doc)
# for examples
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# don't put duplicate lines or lines starting with space in the history.
# See bash(1) for more options
HISTCONTROL=ignoreboth

# append to the history file, don't overwrite it
shopt -s histappend

# for setting history length see HISTSIZE and HISTFILESIZE in bash(1)
HISTSIZE=1000
HISTFILESIZE=2000

# check the window size after each command and, if necessary,
# update the values of LINES and COLUMNS.
shopt -s checkwinsize

# If set, the pattern "**" used in a pathname expansion context will
# match all files and zero or more directories and subdirectories.
#shopt -s globstar

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "${debian_chroot:-}" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# set a fancy prompt (non-color, unless we know we "want" color)
case "$TERM" in
    xterm-color) color_prompt=yes;;
esac

# uncomment for a colored prompt, if the terminal has the capability; turned
# off by default to not distract the user: the focus in a terminal window
# should be on the output of commands, not on the prompt
force_color_prompt=yes

if [ -n "$force_color_prompt" ]; then
    if [ -x /usr/bin/tput ] && tput setaf 1 >&/dev/null; then
	# We have color support; assume it's compliant with Ecma-48
	# (ISO/IEC-6429). (Lack of such support is extremely rare, and such
	# a case would tend to support setf rather than setaf.)
	color_prompt=yes
    else
	color_prompt=
    fi
fi

if [ "$color_prompt" = yes ]; then
    PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
else
    PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
fi
unset color_prompt force_color_prompt

# If this is an xterm set the title to user@host:dir
case "$TERM" in
xterm*|rxvt*)
    PS1="\[\e]0;${debian_chroot:+($debian_chroot)}\u@\h: \w\a\]$PS1"
    ;;
*)
    ;;
esac
# PS1='[\u@\h \W$(__docker_machine_ps1)]\$ '

# get current branch in git repo
function parse_git_branch() {
    BRANCH=`git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/\1/'`
    if [ ! "${BRANCH}" == "" ]
    then
        echo "[${BRANCH}]"
    else
        echo ""
    fi
}
 

# PROMPT_BRANCH='$(parse_git_branch)'
# PS1='${PROMPT_BRANCH}${PS1}'

#export PS1=`hotname`$
# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    #alias dir='dir --color=auto'
    #alias vdir='vdir --color=auto'

    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

# some more ls aliases
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'

# Add an "alert" alias for long running commands.  Use like so:
#   sleep 10; alert
alias alert='notify-send --urgency=low -i "$([ $? = 0 ] && echo terminal || echo error)" "$(history|tail -n1|sed -e '\''s/^\s*[0-9]\+\s*//;s/[;&|]\s*alert$//'\'')"'

# Alias definitions.
# You may want to put all your additions into a separate file like
# ~/.bash_aliases, instead of adding them here directly.
# See /usr/share/doc/bash-doc/examples in the bash-doc package.

if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

# enable programmable completion features (you don't need to enable
# this, if it's already enabled in /etc/bash.bashrc and /etc/profile
# sources /etc/bash.bashrc).
if ! shopt -oq posix; then
  if [ -f /usr/share/bash-completion/bash_completion ]; then
    . /usr/share/bash-completion/bash_completion
  elif [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
  fi
fi
alias vi='vim'
#export PATH=$PATH:/opt/system/software/Xilinx/Vivado_HLS/2016.3/bin:/opt/system/software/Xilinx/Vivado/2016.1/bin
export PATH=/opt/rocm/bin:$PATH
export PATH=/opt/rocm/hcc/bin:$PATH 
export PATH=$HOME/dotfiles/bin:$PATH
#export PICOBASE=/home/jehandad/dev/svn/micron_hmc/branches/picocomputing-5.5.0.0
#alias cdp='cd ~/dev/ccmp4'
#export PATH=$PATH:/home/jehandad/xilinx/Vivado_HLS/2016.3/bin:/home/jehandad/xilinx/Vivado/2016.1/bin
#alias cdp='cd /mnt/c/dev/ccmp4'
#export PICOBASE=/mnt/c/dev/picocomputing-5.5.0.0
alias rm='trash'
# Triggers the bash-completion bug in make files
#alias grep='grep --color=always'
alias grep='grep --color=auto'
function setclocks(){
    rocm-smi --setmclk=3
    rocm-smi --setsclk=7
    rocm-smi --setfan 200
    rocm-smi -a
}
function resetclocks(){
    rocm-smi --resetclocks
    rocm-smi --resetfans
}
export DOTFILES=$HOME/dotfiles
alias cmk_dbg_ocl='cmake -DCMAKE_CXX_FLAGS=-D_GLIBCXX_DEBUG -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DBUILD_DEV="ON" -DCMAKE_BUILD_TYPE="Debug" -DMIOPEN_BACKEND="OpenCL" -DMIOPEN_CACHE_DIR="" _DCMAKE_PREFIX_PATH=/home/jehandad/deps  ..'
alias cmk_ocl='cmake -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DBUILD_DEV="ON" -DCMAKE_BUILD_TYPE="Debug" -DMIOPEN_BACKEND="OpenCL" -DMIOPEN_CACHE_DIR="" -DCMAKE_PREFIX_PATH=/home/jehandad/deps ..'
alias cmk_hip='cmake -DCMAKE_CXX_COMPILER=clang++ -DCMAKE_C_COMPILER=clang -DBUILD_DEV="ON" -DCMAKE_BUILD_TYPE="Debug" -DMIOPEN_BACKEND="HIP" -DMIOPEN_CACHE_DIR="" -DCMAKE_PREFIX_PATH=/home/jehandad/deps ..'
alias tmad='tmux -CC a -d'
alias mj='make -j'
alias md='make -j MIOpenDriver'
alias cdv='cd /Users/jehandad/remote/vega/home/jehandad'
alias cdvml='cd /Users/jehandad/remote/vega/home/jehandad/MLOpen'
export PATH="/usr/local/opt/llvm/bin:$PATH"
# alias for docker 
alias drun="docker run -it -v $HOME:/data --privileged --device=/dev/kfd --device /dev/dri:/dev/dri:rw --volume /dev/dri:/dev/dri:rw -v /var/lib/docker/:/var/lib/docker --group-add video"
# Enable bash-completion on mac
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
# __conda_setup="$('/home/jehandad/anaconda3/bin/conda' 'shell.bash' 'hook' 2> /dev/null)"
# if [ $? -eq 0 ]; then
#     eval "$__conda_setup"
# else
#     if [ -f "/home/jehandad/anaconda3/etc/profile.d/conda.sh" ]; then
#         . "/home/jehandad/anaconda3/etc/profile.d/conda.sh"
#     else
#         export PATH="/home/jehandad/anaconda3/bin:$PATH"
#     fi
# fi
# unset __conda_setup
# <<< conda initialize <<<

