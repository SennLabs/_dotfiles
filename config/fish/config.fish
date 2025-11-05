# Env Var
set -gx EDITOR nvim
set -U fish_greeting


# Colours
set -g fish_color_command --bold green
set -g fish_color_error red
set -g fish_color_quote yellow
set -g fish_color_param white
set -g fish_pager_color_selected_completion brblack
set -g fish_color_valid_path --italics brblue
set -g fish_color_user brmagenta
set -g fish_color_host brcyan
set -g fish_color_host_remote brred



# Nav
abbr .. 'cd ..'
abbr ... 'cd ../..'


# filehandling
abbr rm 'rm -v'
abbr cp 'cp -v'
abbr mv 'mv -v'
alias rmd 'rm -vr'
abbr ls 'ls -a'
abbr grep 'grep --colour=auto'

# 
alias chmox 'chmod +x'

# Apps
alias vi 'nvim'
alias bat 'bat -p'
alias python 'python3'
alias py 'python3'


if status is-interactive
    # Commands to run in interactive sessions can go here
end