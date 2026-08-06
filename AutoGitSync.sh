#!/usr/bin/env bash
# Pull-only dotfile sync. This script never stages, commits, or pushes.
# Safe to run unattended from cron: if the tree is dirty or the local branch
# has diverged, it does nothing rather than risk losing local work.
set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
cd "$repo_dir"

branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" != "main" ]; then
    echo "AutoGitSync: on branch '$branch', not main. Skipping." >&2
    exit 0
fi

# Uncommitted edits mean a fast-forward could fail halfway. Leave them alone.
if [ -n "$(git status --porcelain)" ]; then
    echo "AutoGitSync: working tree has local changes. Skipping." >&2
    exit 0
fi

git fetch --quiet origin main

# --ff-only: never create a merge commit, never rewrite. If local and remote
# have both moved on, that needs a human.
if git merge --ff-only --quiet FETCH_HEAD 2>/dev/null; then
    echo "AutoGitSync: up to date with origin/main."
else
    echo "AutoGitSync: local main has diverged from origin/main. Skipping." >&2
fi
