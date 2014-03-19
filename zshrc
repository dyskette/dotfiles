#-------------------------------------------------------------------------------
# Colors
#-------------------------------------------------------------------------------
autoload -Uz colors
colors

# Make some aliases for the colours: (coud use normal escap.seq's too)
for color in red green yellow blue magenta cyan white; do
    eval z_$color='%{$fg[${(L)color}]%}'
done
z_nocolor="%{$reset_color%}"

# Dircolors
LS_COLORS="di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01:su=31;40;07:sg=36;40;07:tw=32;40;07:ow=33;40;07:"
export LS_COLORS

# Termcap
export LESS_TERMCAP_mb=$(printf "\e[01;31m")    # Begins blinking.
export LESS_TERMCAP_md=$(printf "\e[01;31m")	# Begins bold.
export LESS_TERMCAP_me=$(printf "\e[0m")    	# Ends mode.
export LESS_TERMCAP_se=$(printf "\e[0m")    	# Ends standout-mode.
export LESS_TERMCAP_so=$(printf "\e[00;47;30m")	# Begins standout-mode.
export LESS_TERMCAP_ue=$(printf "\e[0m")    	# Ends underline.
export LESS_TERMCAP_us=$(printf "\e[01;32m")	# Begins underline.

#-------------------------------------------------------------------------------
# Aliases
#-------------------------------------------------------------------------------
alias local-repo="local-repo ${HOME}/aur-repo"
alias history-stat="history 0 | awk '{print \$2}' | sort | uniq -c | sort -n -r | head"

# Modified commands
alias df="df -h"
alias dmesg="dmesg -HL"
alias du="du -c -h"
alias grep="grep --color=auto"
alias less="less -R"
alias ls="ls -hF --color=auto"
alias mkdir="mkdir -p -v"
alias ping="ping -c 5"
alias root="sudo -s"

# Safety features
alias cp="cp -i"
alias ln="ln -i"
alias mv="mv -i"
alias rm="rm -i"
alias chgrp="chgrp --preserve-root"
alias chmod="chmod --preserve-root"
alias chown="chown --preserve-root"

# Error tolerant
alias :q=" exit"
alias :Q=" exit"

#-------------------------------------------------------------------------------
# History
#-------------------------------------------------------------------------------
export HISTFILE="${ZDOTDIR:-$HOME}/.zhistory"
export HISTSIZE=10000
export SAVEHIST=$HISTSIZE

setopt BANG_HIST		# Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY		# Write the history file in the ':start:elapsed;command' format.
setopt INC_APPEND_HISTORY	# Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY		# Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST	# Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS 	# Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS 	# Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS 	# Do not display a previously found event.
setopt HIST_IGNORE_SPACE	# Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS	# Do not write a duplicate event to the history file.
setopt HIST_VERIFY		# Do not execute immediately upon history expansion.
setopt HIST_BEEP		# Beep when accessing non-existent history.

#-------------------------------------------------------------------------------
# Completion
#-------------------------------------------------------------------------------
autoload -Uz compinit
compinit

setopt COMPLETE_IN_WORD		# Complete from both ends of a word
setopt ALWAYS_TO_END		# Move cursor to the end of a completed word
setopt PATH_DIRS		# Path search even on command names with slashes
setopt AUTO_MENU		# Show completion menu on succesive tab press
setopt AUTO_LIST		# Automatically list choices on ambiguous completion

# Use caching to make completion for cammands such as dpkg and apt usable.
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "${ZDOTDIR:-$HOME}/.zcompcache"

# Case-insensitive (all), partial-word, and then substring completion.
if zstyle -t ':prezto:module:completion:*' case-sensitive; then
zstyle ':completion:*' matcher-list 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  setopt CASE_GLOB
else
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
  unsetopt CASE_GLOB
fi

# Group matches and describe.
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:matches' group 'yes'
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format ' %F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format ' %F{purple} -- %d --%f'
zstyle ':completion:*:warnings' format ' %F{red}-- no matches found --%f'
zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' format ' %F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes

# Fuzzy match mistyped completions.
zstyle ':completion:*' completer _complete _match _approximate
zstyle ':completion:*:match:*' original only
zstyle ':completion:*:approximate:*' max-errors 1 numeric

# Increase the number of errors based on the length of the typed word.
zstyle -e ':completion:*:approximate:*' max-errors 'reply=($((($#PREFIX+$#SUFFIX)/3))numeric)'

# Don't complete unavailable commands.
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec))'

# Array completion element sorting.
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Directories
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'
zstyle ':completion:*' squeeze-slashes true

# History
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

# Environmental Variables
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

# Kill
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,comm -w'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

#-------------------------------------------------------------------------------
# Prompt
#-------------------------------------------------------------------------------
autoload -Uz vcs_info
setopt PROMPT_SUBST
precmd () { vcs_info }

# Style the git messages
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:*' check-for-changes true
zstyle ':vcs_info:*' use-prompt-escapes true
zstyle ':vcs_info:*' stagedstr "${z_green} staged${z_nocolor}"
zstyle ':vcs_info:*' unstagedstr "${z_yellow} unstaged${z_nocolor}"
zstyle ':vcs_info:*' actionformats "(%s:%b%u%c - %a)" "[%R/%S]"
zstyle ':vcs_info:*' formats "(${z_green}%s${z_nocolor}:${z_blue}%b${z_nocolor}%u%c)" "[%R/%S]"
zstyle ':vcs_info:git' formats "(${z_red}git${z_nocolor}:${z_blue}%b${z_nocolor}%u%c)" "[%R/%S]"
zstyle ':vcs_info:*' nvcsformats ""

# Check the UID
# Using 'sudo -s' and adding 'Defaults env_keep += "HOME"' to sudoers does the trick
if [[ $UID -ge 1000 ]]; then	# Normal user
    eval z_pwd="${z_cyan}%~"
elif [[ $UID -eq 0 ]]; then	# Root
    eval z_pwd="${z_red}%~"
fi

PROMPT=$'${z_pwd} ${z_green}❯${z_yellow}❯${z_blue}❯ ${z_nocolor}'
RPROMPT=$'${vcs_info_msg_0_}'
