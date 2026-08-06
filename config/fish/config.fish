# Env Var
set -gx EDITOR nvim

# -g not -U: a universal variable is written to fish's own state file, so it
# would persist for anyone who ever ran this config even after removing it.
set -g fish_greeting ""

# Debian and Ubuntu ship these under different binary names than Fedora.
if command -q batcat
    set -gx BAT_CMD batcat
else if command -q bat
    set -gx BAT_CMD bat
end

if command -q fdfind
    set -gx FD_CMD fdfind
else if command -q fd
    set -gx FD_CMD fd
end

if set -q BAT_CMD
    set -gx FZF_DEFAULT_OPTS "--preview '$BAT_CMD --color=always {}'"
    alias bat "$BAT_CMD -p"
end
if set -q FD_CMD
    set -gx FZF_DEFAULT_COMMAND "$FD_CMD --type f"
end


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
abbr -a .. 'cd ..'
abbr -a ... 'cd ../..'


# filehandling
abbr -a rm 'rm -v'
abbr -a cp 'cp -v'
abbr -a mv 'mv -v'
alias rmd 'rm -vr'
alias ls 'ls -a'
alias grep 'grep --colour=auto'
alias chmox 'chmod +x'
alias filecount 'find . -type f | wc -l'

# Apps
alias python 'python3'
alias py 'python3'


if status is-interactive
    # Commands to run in interactive sessions can go here
end
