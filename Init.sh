#!/usr/bin/env bash
# Entry point. Records where this repo lives, then links every config into place.
set -euo pipefail

# Resolve the repo location from the script itself, so this works no matter
# which directory you invoke it from.
dotfiles_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

mkdir -p "$HOME/.config"

# SetupSimLink.sh and SetupCron.sh both read DOTFILEDIR out of this file.
echo "DOTFILEDIR=${dotfiles_dir}" > "$HOME/.config/dotfiles"

bash "$dotfiles_dir/SetupSimLink.sh"

echo
echo "Done. Restart your shell to pick up the new config:  exec \$SHELL -l"
