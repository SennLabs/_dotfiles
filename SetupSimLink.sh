#!/usr/bin/env bash
# Symlinks every config in this repo into place.
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

# Bash on Fedora/RHEL does not source ~/.bash_aliases the way Debian's default
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
for _df in "$HOME/.config/dotfiles_env.sh" "$HOME/.bash_aliases" "$HOME/.bash_functions"; do
    [ -r "$_df" ] && . "$_df"
done
unset _df
# <<< dotfiles <<<
EOF
    echo "->  Added source hook to ~/.bashrc"
}

echo "Linking dotfiles from $DOTFILEDIR"
echo

# Shared helper scripts. tmux.conf and others reference ~/.config/scripts.
link "$DOTFILEDIR/scripts" "$HOME/.config/scripts" "scripts"

# SSH. Must be ~/.ssh/config; ssh does not look in ~/.config. The repo config
# Includes ~/.ssh/config.local so private hosts stay out of a public repo.
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"
link "$config_dir/ssh/config" "$HOME/.ssh/config" "SSH"

# Fish
link "$config_dir/fish/config.fish" "$HOME/.config/fish/config.fish" "fish config"
link "$config_dir/fish/functions"   "$HOME/.config/fish/functions"   "fish functions"

# Editors and terminals
link "$config_dir/nvim"              "$HOME/.config/nvim"     "Neovim"
link "$config_dir/yazi"              "$HOME/.config/yazi"     "Yazi"
link "$config_dir/tmux/tmux.conf"    "$HOME/.tmux.conf"       "Tmux"
link "$config_dir/wezterm/.wezterm.lua" "$HOME/.wezterm.lua"  "WezTerm"

# Bash
link "$config_dir/bash/.bash_aliases"   "$HOME/.bash_aliases"          "Bash aliases"
link "$config_dir/bash/.bash_functions" "$HOME/.bash_functions"        "Bash functions"
link "$config_dir/misc_env_var.sh"      "$HOME/.config/dotfiles_env.sh" "shared env vars"
ensure_bashrc_hook

echo
if [ "$backed_up" -eq 1 ]; then
    echo "Replaced files were saved to: $backup_dir"
fi
echo "Linking complete."
