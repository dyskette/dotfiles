#-------------------------------------------------------------------------------
# General
#-------------------------------------------------------------------------------
alias sudo='sudo '

#-------------------------------------------------------------------------------
# Editor
#-------------------------------------------------------------------------------
export EDITOR=vim

#-------------------------------------------------------------------------------
# Antigen
#-------------------------------------------------------------------------------
if [[ ! -d ~/.antigen ]]; then
	git clone https://github.com/zsh-users/antigen.git ~/.antigen
fi

source ~/.antigen/antigen.zsh

# Load the oh-my-zsh's library.
antigen use oh-my-zsh

# Bundles from the default repo (robbyrussell's oh-my-zsh).
antigen bundle git
antigen bundle command-not-found

# Syntax highlighting bundle.
antigen bundle zsh-users/zsh-syntax-highlighting

# Load the theme.
antigen theme bira

# Tell antigen that you're done.
antigen apply
