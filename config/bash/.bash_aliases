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

# tmux. 'ta' attaches to the 'main' session or creates it -- the normal way to
# pick up where you left off after an SSH link drops.
alias ta='tmux new-session -A -s main'
alias tls='tmux list-sessions'

# Apps
alias py='python3'
alias python='python3'

# EDITOR is resolved with a fallback chain in misc_env_var.sh, so 'vi' points at
# whatever is actually installed rather than assuming nvim.
#
# Expanding at definition time is deliberate in both aliases below: the value is
# resolved once at shell startup and cannot change during the session, so baking
# it in is cheaper and avoids a broken alias if the variable is later unset.
if [ -n "${EDITOR:-}" ]; then
    # shellcheck disable=SC2139
    alias vi="$EDITOR"
fi

# BAT_CMD is resolved in misc_env_var.sh: 'batcat' on Debian/Ubuntu, 'bat'
# elsewhere. Only define the alias if the binary is actually installed.
if [ -n "${BAT_CMD:-}" ]; then
    # shellcheck disable=SC2139
    alias bat="${BAT_CMD} -p"
fi
