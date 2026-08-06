# Shared POSIX-sh environment. Linked to ~/.config/dotfiles_env.sh and sourced
# from ~/.bashrc by SetupSimLink.sh.
#
# Keep this POSIX sh: it is sourced by bash but must not assume bash features.
# The fish equivalent lives in config/fish/config.fish.

# --- Editor ----------------------------------------------------------------
# A headless box may not have nvim, and an EDITOR that does not exist makes
# 'git commit' fail in a confusing way. Take the first one that exists.
for _ed in nvim vim vi nano; do
    if command -v "$_ed" >/dev/null 2>&1; then
        EDITOR="$_ed"
        break
    fi
done
unset _ed
if [ -n "${EDITOR:-}" ]; then
    export EDITOR
    export VISUAL="$EDITOR"
fi

# --- Locale ----------------------------------------------------------------
# Minimal server images often leave LANG unset or set to C, which mangles the
# box-drawing characters in tmux, yazi and git's output. Only pick a locale the
# host actually has generated.
case "${LANG:-}" in
    ""|C|POSIX)
        for _loc in C.UTF-8 C.utf8 en_US.UTF-8 en_AU.UTF-8; do
            if locale -a 2>/dev/null | grep -qxF "$_loc"; then
                export LANG="$_loc"
                break
            fi
        done
        unset _loc
        ;;
esac

# --- Pager -----------------------------------------------------------------
# -R keeps colour, -i case-insensitive search, -F skips the pager for output
# that fits one screen, -X stops -F from wiping that output on exit.
if command -v less >/dev/null 2>&1; then
    export PAGER=less
    export LESS='-F -R -X -i'
    export LESSHISTFILE=-        # do not litter ~ with .lesshst
fi

# --- bat / fd --------------------------------------------------------------
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

# --- FZF -------------------------------------------------------------------
if [ -n "${BAT_CMD:-}" ]; then
    export FZF_DEFAULT_OPTS="--preview '${BAT_CMD} --color=always {}'"
fi
if [ -n "${FD_CMD:-}" ]; then
    export FZF_DEFAULT_COMMAND="${FD_CMD} --type f"
fi

# Everything above is conditional on some binary being installed, so there is no
# single variable that proves this file ran. This one does, which makes it easy
# to check a login shell really picked the environment up:
#     ssh host 'echo $DOTFILES_ENV'
export DOTFILES_ENV=1
