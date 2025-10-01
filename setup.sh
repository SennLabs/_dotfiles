#!/bin/bash

dotfiles_dir=$(pwd)
config_dir="$(pwd)/config/"

echo "Dir: $dotfiles_dir"
echo "config: $config_dir"

# SimLink For All dotfiles

ln -s "${config_dir}fish/config.fish" ~/.config/fish/config.fish
ln -s "${config_dir}fish/functions" ~/.config/fish/functions

ln -s "${config_dir}nvim" ~/.config/nvim

ln -s "${config_dir}tmux/tmux.conf" ~/.tmux.conf

ln -s "${config_dir}bash/.bash_aliases" ~/.bash_aliases
source ~/.bashrc
