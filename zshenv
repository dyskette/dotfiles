#-------------------------------------------------------------------------------
# Zsh Environmet variables
#-------------------------------------------------------------------------------
# Editors
export EDITOR='vim'
export VISUAL='gvim'
export PAGER='less'

# Browser
if [[ -n "$DISPLAY" ]]; then
    export BROWSER='firefox'
fi

# Language
if [[ -z "$LANG" ]]; then
    export LANG='es_MX.UTF-8'
fi

# Paths
typeset -gU path
path=(
    ~/bin
    $path
)

# Less
export LESS='-F -g -i -M -R -S -w -X -z-4'
