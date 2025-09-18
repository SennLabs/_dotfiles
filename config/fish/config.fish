# Env Var
set -gx EDITOR nvim


# Abbr
abbr rm 'rm -v'
abbr cp 'cp -v'
abbr ls 'ls -a'
abbr mv 'mv -v'
abbr grep 'grep --colour=auto'
abbr .. 'cd ..'
abbr ... 'cd ../..'


# Alias
alias rmd 'rmdir -p'
alias vi 'nvim'
alias bat 'batcat -p'
alias python 'python3'
alias py 'python3'


if status is-interactive
    # Commands to run in interactive sessions can go here
end