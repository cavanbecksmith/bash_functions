alias sshconf="subl ~/.ssh/"

function keys() {
    ls -la "$SSH_PATH"
    xdg-open $SSH_PATH
}

function add_key() {
    # ssh-agent -s
    eval `ssh-agent -s`
    # ssh-add "$SSH_PATH/"$1
    ssh-add $1
}

function create_key() {
    ssh-keygen -t rsa -b 4096 -f "$SSH_PATH/"$1
    # eval $(ssh-agent -s)
    eval `ssh-agent -s`
    ssh-add "$SSH_PATH/"$1
    cat "$SSH_PATH/"$1".pub" | xclip -sel clip
}

function copy_key() {
  clip < $SSH_PATH'\'$1".pub"
}

function remove_key() {
    rm "~/.ssh"$1
    rm "~/.ssh"$1".pub"
}

function ssh_with_key() {
  ssh -i $SSH_PATH'\'$1 "$2"
}

function key_to_server() {
  if [ $1 && $2 ]
  then
    # echo $SSH_PATH'\'$1".pub" "$2"
    ssh-copy-id -i $SSH_PATH'\'$1".pub" "$2"
  fi
}


ssh_list() {
    find ~/.ssh -type f -name '*_config' -exec grep -H '^\s*Host ' {} \; | awk '
    {
        split($0, parts, ":")
        file = parts[1]
        host_line = substr($0, length(file) + 2)
        sub(/^\s*Host\s+/, "", host_line)
        printf "%s: %s\n", file, host_line
    }'
}
