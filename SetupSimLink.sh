#!/bin/bash

set -a && source ~/.config/dotfiles && set +a
config_dir="$DOTFILEDIR/config/"

# SimLink For files

config_created() {
    echo "Added $1 Config"
}

if [ ! -f ~/.config/tools ]; then
    ln -s "$DOTFILEDIR/scripts" ~/.config/scripts
fi


if [ ! -d ~/.config/ssh ]; then
    mkdir ~/.config/ssh
    cat "$DOTFILEDIR/config/ssh/config" >> ~/.config/ssh/config
    config_created "SSH"
else
    if [ ! -f ~/.config/ssh/config ]; then
        cat "$DOTFILEDIR/config/ssh/config" >> ~/.config/ssh/config
        config_created "SSH"
    else
        echo "SSH config exists"
        read -p "Do you want to append it? (y/n) " choice
        if [ "$choice" == "y" ]; then
            cat "$DOTFILEDIR/config/ssh/config" >> ~/.config/ssh/config
            config_created "SSH"
        fi
    fi
fi






# Check if ~/.config/fish exists, if not create it
if [ ! -d ~/.config/fish ]; then
    mkdir ~/.config/fish
    mkdir ~/.config/fish/functions
    ln -s "${config_dir}fish/functions" ~/.config/fish/functions
    ln -s "${config_dir}fish/config.fish" ~/.config/fish/config.fish
    config_created "fish"
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
    config_created "Neovim"
else
    echo "nvim config exists"
    read -p "Do you want to overwrite it? (y/n) " choice
    if [ "$choice" == "y" ]; then
        rm -rf ~/.config/nvim
        ln -s "${config_dir}nvim" ~/.config/nvim
        config_created "Neovim"
    fi
fi


if [ ! -f ~/.tmux.conf ]; then
    ln -s "${config_dir}tmux/tmux.conf" ~/.tmux.conf
    config_created "Tmux"
else
    echo "tmux config exists"
    read -p "Do you want to overwrite it? (y/n) " choice
    if [ "$choice" == "y" ]; then
        rm -rf ~/.tmux.conf
        ln -s "${config_dir}tmux/tmux.conf" ~/.tmux.conf
        config_created "Tmux"
    fi
fi


if [ ! -f ~/.bash_aliases ]; then
    ln -s "${config_dir}bash/.bash_aliases" ~/.bash_aliases
    config_created "Bash"
else
    echo ".bash_aliases exists"
    read -p "Do you want to overwrite it? (y/n) " choice
    if [ "$choice" == "y" ]; then
        rm -rf ~/.bash_aliases
        ln -s "${config_dir}bash/.bash_aliases" ~/.bash_aliases
        config_created "Bash"
    fi
fi
source ~/.bashrc


if [ ! -f ~/.wezterm.lua ]; then
    ln -s "${config_dir}wezterm/.wezterm.lua" ~/.wezterm.lua
    config_created "WezTerm"
else
    echo ".wezterm.lua exists"
    read -p "Do you want to overwrite it? (y/n) " choice
    if [ "$choice" == "y" ]; then
        rm -rf ~/.wezterm.lua
        ln -s "${config_dir}wezterm/.wezterm.lua" ~/.wezterm.lua
        config_created "WezTerm"
    fi
fi    


echo "End Of Script"
