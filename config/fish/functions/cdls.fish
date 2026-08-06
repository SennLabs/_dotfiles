function cdls --description 'Move to specified dir and list files inside'
    cd $argv
    and ls -a --color=auto
end
