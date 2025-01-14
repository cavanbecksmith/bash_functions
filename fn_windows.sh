alias open="explorer"
alias 7z='"C://Program Files/7-Zip/7z.exe"'
alias startup="cd 'C:\Users\\$USER\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\Startup'"
alias hosts="nano 'C:\Windows\System32\drivers\etc\hosts'"
# VBOX
alias VBoxManage='"/c/Program Files/Oracle/VirtualBox/VBoxManage.exe"'
# QEMU
alias qemu='"/c/Program Files/qemu/qemu-system-x86_64.exe"'
alias qemu-system-x86_64='"/c/Program Files/qemu/qemu-system-x86_64.exe"'
alias qemu-img='"/c/Program Files/qemu/qemu-img"'
# Android
alias droidkeystore="keytool -list -v -keystore ./android/app/debug.keystore -alias androiddebugkey -storepass android -keypass android"
# Browser
alias brave='"/c/Program Files/BraveSoftware/Brave-Browser/Application/brave.exe"'
# 
alias syncthing="C://Users/$USER/Documents/syncthing-windows-amd64-v1.23.1/syncthing.exe"
alias lazygit="/c/Software/lazygit/lazygit.exe"

function subl(){
    /c/Program\ Files/Sublime\ Text/sublime_text.exe $1 &
    #/c/Software/Sublime\ Text/sublime_text.exe $1&
    return
}

