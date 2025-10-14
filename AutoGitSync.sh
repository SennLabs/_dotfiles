#!/bin/bash
#cd ~/dotfiles_repo # Your cloned dotfiles repository
git add .
git commit -m "Automated dotfile sync" || true # '|| true' prevents script failure if no changes
git pull --rebase origin main
git push origin main