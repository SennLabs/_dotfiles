#!/usr/bin/env bash
# Symlinks every config in this repo into place.
#
#   ./SetupSimLink.sh [--profile core|container|server|desktop]
#
# Idempotent and non-destructive: re-running is a no-op, and anything already
# living at a target path is moved into ~/.dotfiles-backup/<timestamp>/ rather
# than deleted. No prompts, so it is safe in a provisioning script.
set -euo pipefail

# Prefer the path Init.sh recorded, but fall back to this script's own location
# so SetupSimLink.sh can be run directly on a fresh machine.
if [ -r "$HOME/.config/dotfiles" ]; then
    set -a && source "$HOME/.config/dotfiles" && set +a
fi
: "${DOTFILEDIR:=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"

profile="${DOTFILEPROFILE:-server}"
while [ $# -gt 0 ]; do
    case "$1" in
        --profile) profile="${2:?--profile needs a value}"; shift 2;;
        --profile=*) profile="${1#*=}"; shift;;
        *) echo "Unknown option: $1" >&2; exit 2;;
    esac
done

config_dir="$DOTFILEDIR/config"
backup_dir="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
backed_up=0

# Move whatever is at $1 into the backup directory, preserving its name.
backup() {
    mkdir -p "$backup_dir"
    backed_up=1
    mv -- "$1" "$backup_dir/"
    echo "    backed up existing $(basename -- "$1") -> $backup_dir/"
}

# link <source> <target> <label>
link() {
    local src=$1 dest=$2 label=$3

    if [ ! -e "$src" ]; then
        echo "!!  $label: source missing ($src), skipping" >&2
        return 0
    fi

    # Already pointing where we want it. -L before -e, because a symlink whose
    # target is gone is invisible to -e but still needs replacing.
    if [ -L "$dest" ] && [ "$(readlink -f -- "$dest")" = "$(readlink -f -- "$src")" ]; then
        echo "==  $label already linked"
        return 0
    fi

    if [ -L "$dest" ]; then
        rm -- "$dest"          # a wrong or dangling symlink is not worth backing up
    elif [ -e "$dest" ]; then
        backup "$dest"
    fi

    mkdir -p "$(dirname -- "$dest")"
    ln -s -- "$src" "$dest"
    echo "->  Linked $label"
}

# Aliases and functions are interactive-only, so ~/.bashrc is the right home for
# them. Fedora/RHEL does not source ~/.bash_aliases the way Debian's default
# ~/.bashrc does, so wire it up explicitly. Marker-delimited and added once.
ensure_bashrc_hook() {
    local rc="$HOME/.bashrc"
    if [ -f "$rc" ] && grep -qF ">>> dotfiles >>>" "$rc"; then
        echo "==  .bashrc hook already present"
        return 0
    fi
    cat >> "$rc" <<'EOF'

# >>> dotfiles >>>
# Env first: .bash_aliases reads BAT_CMD, which dotfiles_env.sh resolves.
# (Also sourced from the login file, for shells that never read ~/.bashrc.)
for _df in "$HOME/.config/dotfiles_env.sh" "$HOME/.bash_aliases" "$HOME/.bash_functions"; do
    [ -r "$_df" ] && . "$_df"
done
unset _df
# <<< dotfiles <<<
EOF
    echo "->  Added source hook to ~/.bashrc"
}

# True if $1 contains a real 'source'/'.' of bashrc. Comments are stripped
# first: a file merely *mentioning* bashrc in prose must not count as wired up.
# Note the here-string rather than 'sed ... | grep -q': under 'set -o pipefail'
# grep -q exits on the first match, sed dies of SIGPIPE, and the pipeline
# reports failure even when the pattern was found.
sources_bashrc() {
    [ -f "$1" ] || return 1
    local stripped
    stripped=$(sed 's/#.*//' "$1" 2>/dev/null || true)
    grep -qE '(^|[[:space:];&|(])(\.|source)[[:space:]]+[^;&|]*bashrc' <<<"$stripped"
}

# SSH gives you a *login* shell, which reads ~/.bash_profile or ~/.profile --
# never ~/.bashrc directly. Two things go wrong without this:
#
#   1. Minimal images sometimes ship neither file, so nothing chains to
#      ~/.bashrc and the hook above never runs at all.
#   2. Ubuntu's stock ~/.bashrc returns early when non-interactive
#      ([ -z "$PS1" ] && return), so anything appended to it is invisible to a
#      non-interactive login shell. Environment variables must not sit behind
#      that guard -- EDITOR and LANG are needed by 'ssh host -t <cmd>' too.
#
# So: env goes in the login file, aliases/functions stay in ~/.bashrc.
ensure_login_shell_hook() {
    local rc="$HOME/.profile"
    # A ~/.bash_profile, if present, shadows ~/.profile entirely.
    [ -f "$HOME/.bash_profile" ] && rc="$HOME/.bash_profile"

    if [ -f "$rc" ] && grep -qF ">>> dotfiles login >>>" "$rc"; then
        echo "==  login hook already present in ${rc##*/}"
        return 0
    fi

    # Decide before writing: appending would otherwise change what we detect.
    local need_chain=0
    sources_bashrc "$rc" || need_chain=1

    {
        echo ""
        echo "# >>> dotfiles login >>>"
        echo "# Environment for every login shell, including non-interactive ones,"
        echo "# which never reach ~/.bashrc."
        echo '[ -r "$HOME/.config/dotfiles_env.sh" ] && . "$HOME/.config/dotfiles_env.sh"'
        if [ "$need_chain" -eq 1 ]; then
            echo '# Interactive login shells also need ~/.bashrc for aliases and functions.'
            echo '[ -n "$BASH_VERSION" ] && [ -r "$HOME/.bashrc" ] && . "$HOME/.bashrc"'
        fi
        echo "# <<< dotfiles login <<<"
    } >> "$rc"

    if [ "$need_chain" -eq 1 ]; then
        echo "->  Added login hook to ${rc##*/} (env + ~/.bashrc chain)"
    else
        echo "->  Added login hook to ${rc##*/} (env; already chained ~/.bashrc)"
    fi
}

echo "Linking dotfiles from $DOTFILEDIR (profile: $profile)"
echo

# Shared helper scripts. tmux.conf and others reference ~/.config/scripts.
link "$DOTFILEDIR/scripts" "$HOME/.config/scripts" "scripts"

# SSH. Must be ~/.ssh/config; ssh does not look in ~/.config. The repo config
# Includes ~/.ssh/config.local so private hosts stay out of a public repo.
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
link "$config_dir/ssh/config" "$HOME/.ssh/config" "SSH"

# Fish and Yazi are outside the container package set, and yazi has no apt
# package at all, so on that profile these would only leave config behind for
# tools the image is never going to have.
if [ "$profile" != "container" ]; then
    link "$config_dir/fish/config.fish" "$HOME/.config/fish/config.fish" "fish config"
    link "$config_dir/fish/functions"   "$HOME/.config/fish/functions"   "fish functions"
    link "$config_dir/yazi"             "$HOME/.config/yazi"             "Yazi"
else
    echo "..  skipping fish and yazi configs for profile 'container'"
fi

# Editors and terminals
link "$config_dir/nvim"           "$HOME/.config/nvim" "Neovim"
link "$config_dir/tmux/tmux.conf" "$HOME/.tmux.conf"   "Tmux"

# Git. ~/.config/git/config is git's own XDG location; the shared config
# Includes ~/.config/git/config.local, which holds user.name/user.email so no
# identity is committed to a public repo.
#
# The XDG path rather than ~/.gitconfig is a deliberate choice, not an
# arbitrary one: a dev container is handed a copy of the host's ~/.gitconfig,
# git reads that *after* this file, and so the host wins wherever the two
# disagree. That is the behaviour we want -- your real identity and your own
# preferences follow you in -- and everything the host leaves unset still comes
# from here.
link "$config_dir/git/config" "$HOME/.config/git/config" "Git"

# Readline, for every bare bash prompt over SSH.
link "$config_dir/readline/inputrc" "$HOME/.inputrc" "readline"

# Bash
link "$config_dir/bash/.bash_aliases"   "$HOME/.bash_aliases"           "Bash aliases"
link "$config_dir/bash/.bash_functions" "$HOME/.bash_functions"         "Bash functions"
link "$config_dir/misc_env_var.sh"      "$HOME/.config/dotfiles_env.sh" "shared env vars"
ensure_bashrc_hook
ensure_login_shell_hook

# GUI-only configs. Linking these on a headless box is harmless but pointless,
# and it makes 'desktop' vs 'server' actually mean something.
if [ "$profile" = "desktop" ]; then
    link "$config_dir/wezterm/.wezterm.lua" "$HOME/.wezterm.lua" "WezTerm"
    link "$config_dir/kzones/layouts.json" \
         "$HOME/.local/share/kzones/layouts.json" "KZones"
else
    echo "..  skipping GUI configs (WezTerm, KZones) for profile '$profile'"
fi

echo
if [ "$backed_up" -eq 1 ]; then
    echo "Replaced files were saved to: $backup_dir"
fi
echo "Linking complete."
