#!/usr/bin/env bash
# Entry point. Records where this repo lives, then links every config into place.
#
#   ./Init.sh [--profile core|container|server|desktop] [--apps]
#
# server (the default) skips GUI-only configs; desktop links everything;
# container drops the configs for tools a dev container will not have.
# --apps also runs InstallApps.sh for the same profile, after linking.
set -euo pipefail

# Resolve the repo location from the script itself, so this works no matter
# which directory you invoke it from.
dotfiles_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)

profile="server"
install_apps=0

while [ $# -gt 0 ]; do
    case "$1" in
        --profile) profile="${2:?--profile needs a value}"; shift 2;;
        --profile=*) profile="${1#*=}"; shift;;
        --apps) install_apps=1; shift;;
        -h|--help) sed -n '2,8p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        *) echo "Unknown option: $1" >&2; exit 2;;
    esac
done

case "$profile" in
    core|container|server|desktop) ;;
    *) echo "Invalid profile '$profile' (want core, container, server or desktop)" >&2; exit 2;;
esac

mkdir -p "$HOME/.config"

# SetupSimLink.sh and SetupCron.sh both read DOTFILEDIR out of this file.
{
    echo "DOTFILEDIR=${dotfiles_dir}"
    echo "DOTFILEPROFILE=${profile}"
} > "$HOME/.config/dotfiles"

bash "$dotfiles_dir/SetupSimLink.sh" --profile "$profile"

# Packages come after the linking, and cannot fail the run. The two steps are
# not equally recoverable: a package manager that is briefly unreachable is
# retried with one command, whereas aborting beforehand -- which is what used
# to happen, under 'set -e' -- left the machine with no config at all.
if [ "$install_apps" -eq 1 ]; then
    echo
    if ! bash "$dotfiles_dir/InstallApps.sh" --profile "$profile"; then
        echo
        echo "!!  Package installation failed. The configs above are linked," >&2
        echo "    so this is safe to retry on its own:" >&2
        echo "      bash $dotfiles_dir/InstallApps.sh --profile $profile" >&2
    fi
fi

echo
echo "Done. Restart your shell to pick up the new config:  exec \$SHELL -l"
