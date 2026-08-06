#!/bin/bash

set -a && source ~/.config/dotfiles && set +a

GitSyncScript="$(DOTFILEDIR)/AutoGitSync.sh"

(crontab -l; echo "0 */2 * * * ${GitSyncScript}") | sort -u | crontab -
