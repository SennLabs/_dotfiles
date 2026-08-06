# Bash equivalents of the fish functions in config/fish/functions/.
#
# These have to be functions, not scripts: a script runs in a child process, so
# any 'cd' it does dies with it and your shell never moves.

# Create a directory (including parents) and cd into it.
mkc() {
    if [ $# -eq 0 ]; then
        echo "usage: mkc <dir>" >&2
        return 2
    fi
    mkdir -p -- "$1" && cd -- "$1"
}

# cd into a directory and immediately list it.
cdls() {
    cd -- "${1:-$HOME}" || return
    ls -a --color=auto
}

# ls -ahl with column headers, aligned.
lsh() {
    {
        echo "Permissions Links Owner Group Size Modified-Month Day Time Name"
        ls -ahl "$@" | tail -n +2
    } | column -t
}
