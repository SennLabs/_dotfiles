#!/bin/bash

#dotfiles_dir=$(pwd)
GitSyncScript="$(pwd)/AutoGitSync.sh"

(crontab -l; echo "0 */2 * * * ${config_dir}") | sort -u | crontab -
