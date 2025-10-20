#!/bin/bash

dotfiles_dir=$(pwd)
config_dir="$(pwd)/config/"

echo "Dir: $dotfiles_dir"
echo "config: $config_dir"

# SimLink For files


# Check if ~/.config exists, if not create it
if [ ! -d ~/.config ]; then
    mkdir ~/.config
fi



# Check if ~/.config/fish exists, if not create it
if [ ! -d ~/.config/fish ]; then
    mkdir ~/.config/fish
    mkdir ~/.config/fish/functions
    ln -s "${config_dir}fish/functions" ~/.config/fish/functions
    ln -s "${config_dir}fish/config.fish" ~/.config/fish/config.fish
else
    if [ -e "~/.config/fish/config.fish" ]; then
        echo "config.fish exists"
        read -p "Do you want to overwrite it? (y/n) " choice
        if [ "$choice" == "y" ]; then
            rm ~/.config/fish/config.fish
            ln -s "${config_dir}fish/config.fish" ~/.config/fish/config.fish
        fi
    else
        ln -s "${config_dir}fish/config.fish" ~/.config/fish/config.fish
    fi
    if [ ! -d ~/.config/fish/functions ]; then
        ln -s "${config_dir}fish/functions" ~/.config/fish/functions
    fi
fi


if [ ! -d ~/.config/nvim ]; then
    ln -s "${config_dir}nvim" ~/.config/nvim
else
    echo "nvim config exists"
    read -p "Do you want to overwrite it? (y/n) " choice
    if [ "$choice" == "y" ]; then
        rm -rf ~/.config/nvim
        ln -s "${config_dir}nvim" ~/.config/nvim
    fi
fi


if [ ! -f ~/.tmux.conf ]; then
    ln -s "${config_dir}tmux/tmux.conf" ~/.tmux.conf
else
    echo "tmux config exists"
    read -p "Do you want to overwrite it? (y/n) " choice
    if [ "$choice" == "y" ]; then
        rm -rf ~/.tmux.conf
        ln -s "${config_dir}tmux/tmux.conf" ~/.tmux.conf
    fi
fi


if [ ! -f ~/.bash_aliases ]; then
    ln -s "${config_dir}bash/.bash_aliases" ~/.bash_aliases
else
    echo ".bash_aliases exists"
    read -p "Do you want to overwrite it? (y/n) " choice
    if [ "$choice" == "y" ]; then
        rm -rf ~/.bash_aliases
        ln -s "${config_dir}bash/.bash_aliases" ~/.bash_aliases
    fi
fi
source ~/.bashrc


