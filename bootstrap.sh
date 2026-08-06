#!/bin/sh
# One-shot bootstrap for a fresh (usually headless) machine.
#
#   curl -fsSL https://raw.githubusercontent.com/SennLabs/_dotfiles/main/bootstrap.sh | sh
#
# Installs git, clones this repo, and runs Init.sh. Safe to re-run: an existing
# clone is fast-forwarded rather than re-cloned.
#
# Override with environment variables:
#   DOTFILES_DIR=~/_dotfiles      where to clone
#   DOTFILES_REPO=<url>           source repo
#   DOTFILES_REF=main             branch or tag to check out
#   DOTFILES_PROFILE=server       core | server | desktop
#   DOTFILES_APPS=0               set to 1 to also install packages
#
# POSIX sh on purpose: this runs before anything is guaranteed to be present.
set -eu

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/_dotfiles}"
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/SennLabs/_dotfiles.git}"
DOTFILES_REF="${DOTFILES_REF:-main}"
DOTFILES_PROFILE="${DOTFILES_PROFILE:-server}"
DOTFILES_APPS="${DOTFILES_APPS:-0}"

say() { printf '==> %s\n' "$*"; }
die() { printf 'error: %s\n' "$*" >&2; exit 1; }

if [ "$(id -u)" -eq 0 ]; then
    SUDO=""
elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
else
    SUDO=""
fi

# --- Make sure git exists --------------------------------------------------
need_install=""
command -v git  >/dev/null 2>&1 || need_install="$need_install git"
command -v bash >/dev/null 2>&1 || need_install="$need_install bash"

if [ -n "$need_install" ]; then
    say "installing:$need_install"
    if command -v apt-get >/dev/null 2>&1; then
        DEBIAN_FRONTEND=noninteractive $SUDO apt-get update -qq
        # shellcheck disable=SC2086
        DEBIAN_FRONTEND=noninteractive $SUDO apt-get install -y --no-install-recommends \
            ca-certificates $need_install
    elif command -v dnf >/dev/null 2>&1; then
        # shellcheck disable=SC2086
        $SUDO dnf install -y ca-certificates $need_install
    else
        die "no apt-get or dnf; install${need_install} manually and re-run"
    fi
fi

# The rest of the repo is bash, not POSIX sh (arrays, mapfile, BASH_SOURCE).
command -v bash >/dev/null 2>&1 || die "bash is required but could not be installed"

# --- Clone or update -------------------------------------------------------
if [ -d "$DOTFILES_DIR/.git" ]; then
    say "existing clone at $DOTFILES_DIR, fetching"
    git -C "$DOTFILES_DIR" fetch --quiet origin "$DOTFILES_REF"
    # --ff-only so local edits are never silently discarded.
    if ! git -C "$DOTFILES_DIR" merge --ff-only --quiet FETCH_HEAD 2>/dev/null; then
        say "could not fast-forward (local changes or diverged); using tree as-is"
    fi
elif [ -e "$DOTFILES_DIR" ]; then
    die "$DOTFILES_DIR exists but is not a git clone; move it aside first"
else
    say "cloning $DOTFILES_REPO into $DOTFILES_DIR"
    git clone --quiet --branch "$DOTFILES_REF" "$DOTFILES_REPO" "$DOTFILES_DIR"
fi

# --- Optionally install packages ------------------------------------------
if [ "$DOTFILES_APPS" = "1" ]; then
    say "installing packages for profile '$DOTFILES_PROFILE'"
    bash "$DOTFILES_DIR/InstallApps.sh" --profile "$DOTFILES_PROFILE" --yes
fi

# --- Link the configs ------------------------------------------------------
say "linking configs (profile: $DOTFILES_PROFILE)"
bash "$DOTFILES_DIR/Init.sh" --profile "$DOTFILES_PROFILE"

say "bootstrap complete"
