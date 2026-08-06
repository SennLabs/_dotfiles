# Shared POSIX-sh environment. Linked to ~/.config/dotfiles_env.sh and sourced
# from ~/.bashrc by SetupSimLink.sh.

export EDITOR=nvim

# Debian and Ubuntu ship these tools under different binary names than Fedora,
# because the short names collided with existing packages. Detect once.
if command -v batcat >/dev/null 2>&1; then
    BAT_CMD=batcat
elif command -v bat >/dev/null 2>&1; then
    BAT_CMD=bat
fi

if command -v fdfind >/dev/null 2>&1; then
    FD_CMD=fdfind
elif command -v fd >/dev/null 2>&1; then
    FD_CMD=fd
fi

export BAT_CMD FD_CMD

# FZF configuration
if [ -n "${BAT_CMD:-}" ]; then
    export FZF_DEFAULT_OPTS="--preview '${BAT_CMD} --color=always {}'"
fi
if [ -n "${FD_CMD:-}" ]; then
    export FZF_DEFAULT_COMMAND="${FD_CMD} --type f"
fi
