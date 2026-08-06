# Navigation
alias ..='cd ..'
alias ...='cd ../..'

# filehandling
alias rm='rm -v'
alias cp='cp -v'
alias mv='mv -v'
alias rmd='rm -vr'

alias lsa='ls --color=auto -a'
alias grep='grep --colour=auto'
alias chmox='chmod +x'
alias filecount='find . -type f | wc -l'

# Apps
alias vi='nvim'
alias py='python3'
alias python='python3'

# BAT_CMD is resolved in misc_env_var.sh: 'batcat' on Debian/Ubuntu, 'bat'
# elsewhere. Only define the alias if the binary is actually installed.
if [ -n "${BAT_CMD:-}" ]; then
    alias bat="${BAT_CMD} -p"
fi
