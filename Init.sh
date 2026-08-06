#!/bin/bash

dotfiles_dir=$(pwd)

# Check if ~/.config exists, if not create it
if [ ! -d ~/.config ]; then
    mkdir ~/.config

fi

echo "DOTFILEDIR=${dotfiles_dir}" >| ~/.config/dotfiles

bash ./SetupSimLink.sh


