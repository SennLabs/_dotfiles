function lsh --wraps='ls -ahl' --description 'See list of all files and dir with all details and header names | base cmd: ls -ahl'
    echo "Permissions|Owner|Group|Size|Modified|Name"
    ls -ahl $argv | tail -n +2
end