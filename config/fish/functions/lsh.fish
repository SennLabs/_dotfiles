function lsh --wraps='ls -ahl' --description 'See list of all files and dir with all details and header names | base cmd: ls -ahl'
    # 'column' is bsdextrautils on Debian/Ubuntu and util-linux on Fedora, and is
    # absent from minimal images, so fall back to unaligned output.
    if command -q column
        begin
            echo "Permissions Links Owner Group Size Modified-Month Day Time Name"
            ls -ahl $argv | tail -n +2
        end | column -t
    else
        echo "Permissions Links Owner Group Size Modified Name"
        ls -ahl $argv | tail -n +2
    end
end
