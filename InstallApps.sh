#!/usr/bin/env bash
# Installs packages from apps/app_list.csv for a given profile.
#
#   ./InstallApps.sh [--profile core|server|desktop] [--dry-run] [--yes]
#
# Profiles are cumulative: server includes core, desktop includes both.
# Packages not available in the host's repos are reported and skipped rather
# than failing the run, because package names drift between distro versions.
#
# Supports apt (Debian/Ubuntu), dnf (Fedora/RHEL) and Termux on Android, which
# ships its own apt with different package names and no root or sudo at all.
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
csv="$repo_dir/apps/app_list.csv"

profile="server"
dry_run=0
assume_yes=0

while [ $# -gt 0 ]; do
    case "$1" in
        --profile) profile="${2:?--profile needs a value}"; shift 2;;
        --profile=*) profile="${1#*=}"; shift;;
        --dry-run) dry_run=1; shift;;
        --yes|-y) assume_yes=1; shift;;
        -h|--help) sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
        *) echo "Unknown option: $1" >&2; exit 2;;
    esac
done

case "$profile" in
    core|server|desktop) ;;
    *) echo "Invalid profile '$profile' (want core, server or desktop)" >&2; exit 2;;
esac

[ -r "$csv" ] || { echo "Cannot read $csv" >&2; exit 1; }

# --- Detect the package manager -------------------------------------------
# Termux must be checked first: it has apt-get too, but with its own package
# names, so it gets its own CSV column.
is_termux() {
    [ -n "${TERMUX_VERSION:-}" ] && return 0
    case "${PREFIX:-}" in */com.termux/*) return 0;; esac
    return 1
}

if is_termux; then
    mgr=termux
    col=10
elif command -v apt-get >/dev/null 2>&1; then
    mgr=apt
    col=7
elif command -v dnf >/dev/null 2>&1; then
    mgr=dnf
    col=8
else
    echo "No supported package manager found (need apt-get, dnf or Termux)." >&2
    echo "On Windows use InstallApps.ps1 instead." >&2
    exit 1
fi

# root already has the privileges; otherwise we need sudo. Termux is the
# exception: it is never root, has no sudo, and its apt installs unprivileged
# into the app's own prefix.
if [ "$mgr" = termux ] || [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    echo "Not root and sudo is not installed; cannot install packages." >&2
    exit 1
fi

# --- Select rows for this profile -----------------------------------------
# Cumulative: core=4, server=5, desktop=6 are the flag columns.
case "$profile" in
    core)    want='$4=="1"' ;;
    server)  want='$4=="1" || $5=="1"' ;;
    desktop) want='$4=="1" || $5=="1" || $6=="1"' ;;
esac

# Field $col holds the package name(s) for this manager, or "-" if unavailable.
# A field may list several space-separated packages (e.g. "python3 python3-pip").
mapfile -t requested < <(
    awk -F',' -v want_col="$col" '
        NR == 1 { next }
        NF < 10 { next }
        '"$want"' {
            if ($want_col != "-" && $want_col != "") print $want_col
        }
    ' "$csv" | tr ' ' '\n' | grep -v '^$' | sort -u
)

mapfile -t unavailable < <(
    awk -F',' -v want_col="$col" '
        NR == 1 { next }
        NF < 10 { next }
        '"$want"' {
            if ($want_col == "-") print $1
        }
    ' "$csv" | sort -u
)

if [ ${#requested[@]} -eq 0 ]; then
    echo "Nothing to install for profile '$profile' with $mgr."
    exit 0
fi

echo "Profile:         $profile"
echo "Package manager: $mgr"
echo "Candidates:      ${#requested[@]}"
echo

# --- Refresh metadata so availability checks are meaningful ----------------
# Without repo metadata every package looks missing. Refresh whenever we can do
# it without springing a sudo password prompt on a --dry-run (root and Termux
# never need one).
metadata_fresh=0
if [ -z "$SUDO" ] || [ "$dry_run" -eq 0 ]; then
    echo "Refreshing package metadata..."
    case "$mgr" in
        apt|termux) $SUDO apt-get update -qq && metadata_fresh=1 ;;
        dnf)        $SUDO dnf -q makecache && metadata_fresh=1 ;;
    esac
    echo
fi

# --- Split into available / missing ---------------------------------------
# apt: an unknown package prints nothing; a known-but-uninstallable one prints
#   "Candidate: (none)", which must not count as available.
# dnf: 'list --available --installed' is rejected by dnf5, so use repoquery,
#   which exists in both dnf4 and dnf5 and prints nothing for an unknown name.
available=()
missing=()
for pkg in "${requested[@]}"; do
    case "$mgr" in
        apt|termux)
            # Captured to a variable rather than piped into grep -q: under
            # 'set -o pipefail', grep -q exits on the first match, apt-cache
            # then dies of SIGPIPE, and the pipeline reports failure even
            # though the package was found.
            policy=$(apt-cache policy "$pkg" 2>/dev/null || true)
            # "Candidate: (none)" means known to apt but not installable.
            if [ -n "$policy" ] && grep -q 'Candidate: [^(]' <<<"$policy"; then
                available+=("$pkg")
            else
                missing+=("$pkg")
            fi
            ;;
        dnf)
            # No '--' separator: dnf5 rejects it outright. Safe here because
            # package names come from the CSV and never begin with a dash.
            if [ -n "$(dnf -q repoquery --qf '%{name}' "$pkg" 2>/dev/null)" ]; then
                available+=("$pkg")
            else
                missing+=("$pkg")
            fi
            ;;
    esac
done

# Everything missing almost always means stale metadata, not 30 absent packages.
if [ ${#available[@]} -eq 0 ] && [ "$metadata_fresh" -eq 0 ]; then
    echo "Warning: no package resolved, and repo metadata was not refreshed." >&2
    echo "         Re-run as root or without --dry-run to get a real answer." >&2
    echo >&2
fi

if [ ${#available[@]} -gt 0 ]; then
    echo "Will install (${#available[@]}): ${available[*]}"
fi
if [ ${#missing[@]} -gt 0 ]; then
    echo
    echo "Not in this host's repos, skipping (${#missing[@]}): ${missing[*]}"
    echo "  These usually need a third-party repo. Package names also differ"
    echo "  between distro releases, so check before assuming it is missing."
fi
if [ ${#unavailable[@]} -gt 0 ]; then
    echo
    echo "No $mgr package defined in the CSV for: ${unavailable[*]}"
fi

if [ "$dry_run" -eq 1 ]; then
    echo
    echo "--dry-run: nothing was installed."
    exit 0
fi
if [ ${#available[@]} -eq 0 ]; then
    echo
    echo "Nothing installable. Done."
    exit 0
fi

echo
if [ "$assume_yes" -eq 0 ] && [ -t 0 ]; then
    read -r -p "Proceed? (y/N) " reply
    case "$reply" in [yY]*) ;; *) echo "Aborted."; exit 0;; esac
fi

case "$mgr" in
    apt) DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y --no-install-recommends -- "${available[@]}" ;;
    # dnf5 rejects '--'; the names come from the CSV, so no separator is needed.
    dnf) $SUDO dnf install -y "${available[@]}" ;;
    # pkg is Termux's apt wrapper; it handles mirror selection, which a raw
    # apt-get does not.
    termux) pkg install -y "${available[@]}" ;;
esac

echo
echo "Install complete for profile '$profile'."
