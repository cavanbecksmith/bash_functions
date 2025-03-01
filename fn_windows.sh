alias open="explorer"
alias 7z='"C://Program Files/7-Zip/7z.exe"'
alias startup="cd 'C:\Users\\$USER\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'"
alias hosts="nano 'C:\Windows\System32\drivers\etc\hosts'"
alias VBoxManage='"/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"'
alias qemu='"/c/Program Files/qemu/qemu-system-x86_64.exe"'
alias qemu-system-x86_64='"/c/Program Files/qemu/qemu-system-x86_64.exe"'
alias qemu-img='"/c/Program Files/qemu/qemu-img"'

function subl(){
    /c/Program\ Files/Sublime\ Text/sublime_text.exe $1 &
    return
}


