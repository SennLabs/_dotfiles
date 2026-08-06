# Fish equivalent of config/misc_env_var.sh. Fish cannot source POSIX sh, so the
# detection logic is deliberately mirrored here rather than shared.

# --- Editor ----------------------------------------------------------------
# A headless box may not have nvim; an EDITOR that does not exist breaks
# 'git commit'. Take the first one that is actually installed.
for _ed in nvim vim vi nano
    if command -q $_ed
        set -gx EDITOR $_ed
        set -gx VISUAL $_ed
        break
    end
end

# -g not -U: a universal variable is written to fish's own state file, so it
# would persist for anyone who ever ran this config even after removing it.
set -g fish_greeting ""

# --- Locale ----------------------------------------------------------------
# Minimal server images often leave LANG unset or set to C, which mangles
# box-drawing characters in tmux and yazi.
if not set -q LANG; or contains -- "$LANG" C POSIX
    for _loc in C.UTF-8 C.utf8 en_US.UTF-8 en_AU.UTF-8
        if locale -a 2>/dev/null | string match -qx -- $_loc
            set -gx LANG $_loc
            break
        end
    end
end

# --- Pager -----------------------------------------------------------------
if command -q less
    set -gx PAGER less
    set -gx LESS '-F -R -X -i'
    set -gx LESSHISTFILE -
end

# --- bat / fd --------------------------------------------------------------
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

# tmux. 'ta' attaches to the 'main' session or creates it -- the normal way to
# pick up where you left off after an SSH link drops.
alias ta 'tmux new-session -A -s main'
alias tls 'tmux list-sessions'

# Apps
alias python 'python3'
alias py 'python3'


if status is-interactive
    # Commands to run in interactive sessions can go here
end
