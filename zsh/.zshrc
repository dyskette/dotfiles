#-------------------------------------------------------------------------------
# General
#-------------------------------------------------------------------------------
#unset SSH_ASKPASS
export WINEARCH=win32
export EDITOR=vim
zstyle ":completion:*:commands" rehash 1          #Rehash for each command
PURE_PROMPT_SYMBOL=$

#-------------------------------------------------------------------------------
# Alias
#-------------------------------------------------------------------------------
alias sudo='sudo '
alias esudo='sudo -E'
alias lanhosts='nmap -sP 192.168.1.1/24'

#-------------------------------------------------------------------------------
# Antigen
#-------------------------------------------------------------------------------
if [[ ! -d ~/.antigen ]]; then
    git clone https://github.com/zsh-users/antigen.git ~/.antigen
fi

source ~/.antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Pure prompt
antigen bundle sindresorhus/pure

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle sudo                               # Shortcut keys: [Esc] [Esc]

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme. Deactivated because it conflicts with pure.
#antigen theme bira

# Tell antigen that you're done.
antigen apply

