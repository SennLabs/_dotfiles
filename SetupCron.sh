#!/usr/bin/env bash
# Installs the pull-only sync (AutoGitSync.sh) on a 2-hourly cron.
# Idempotent: re-running replaces the existing entry instead of duplicating it.
set -euo pipefail

# Prefer the path Init.sh recorded, but fall back to this script's own location
# so SetupCron.sh works even if run before Init.sh.
if [ -r "$HOME/.config/dotfiles" ]; then
    set -a && source "$HOME/.config/dotfiles" && set +a
fi
: "${DOTFILEDIR:=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)}"

GitSyncScript="${DOTFILEDIR}/AutoGitSync.sh"
CronLine="0 */2 * * * ${GitSyncScript}"

# Strip any previous AutoGitSync line first, so moving the repo does not leave
# a stale path behind. '|| true' because grep exits 1 when there is no crontab.
{
    crontab -l 2>/dev/null | grep -Fv "AutoGitSync.sh" || true
    echo "$CronLine"
} | crontab -

echo "Installed cron entry: ${CronLine}"
