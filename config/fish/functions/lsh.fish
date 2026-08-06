function lsh --wraps='ls -ahl' --description 'See list of all files and dir with all details and header names | base cmd: ls -ahl'
    begin
        echo "Permissions Links Owner Group Size Modified-Month Day Time Name"
        ls -ahl $argv | tail -n +2
    end | column -t
end
