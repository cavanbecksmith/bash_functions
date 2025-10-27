alias open="explorer"
alias 7z='"C://Program Files/7-Zip/7z.exe"'
alias startup="cd 'C:\Users\\$USER\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'"
alias hosts="nano 'C:\Windows\System32\drivers\etc\hosts'"
alias VBoxManage='"/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"'
alias qemu='"/c/Program Files/qemu/qemu-system-x86_64.exe"'
alias qemu-system-x86_64='"/c/Program Files/qemu/qemu-system-x86_64.exe"'
alias qemu-img='"/c/Program Files/qemu/qemu-img"'
alias powershellrc="code $HOME/Documents/WindowsPowerShell/Microsoft.PowerShell_profile.ps1"

function subl(){
    /c/Program\ Files/Sublime\ Text/sublime_text.exe $1 &
    return
}

set_gitbash_env() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: set_gitbash_env VAR_NAME VAR_VALUE"
        return 1
    fi

    local VAR_NAME="$1"
    local VAR_VALUE="$2"
    local RC_FILE="$HOME/.bashrc"

    # If the variable is already exported, replace it
    if grep -q "^export ${VAR_NAME}=" "$RC_FILE"; then
        sed -i "s|^export ${VAR_NAME}=.*|export ${VAR_NAME}=\"${VAR_VALUE}\"|" "$RC_FILE"
        echo "Updated $VAR_NAME in $RC_FILE"
    else
        echo "export ${VAR_NAME}=\"${VAR_VALUE}\"" >> "$RC_FILE"
        echo "Added $VAR_NAME to $RC_FILE"
    fi

    # Apply it immediately to current session
    export "${VAR_NAME}=${VAR_VALUE}"
}
# set_gitbash_env MY_VAR my_value
