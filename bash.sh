# CORE COMMANDS
alias edit="subl ~/.bashrc && subl ~/bash_functions"
alias editn="nano ~/.bashrc"
alias edit_subl="subl ~/.bashrc"
alias ref=". ~/.bashrc"
alias ..="cd ../"
alias ...="cd ../../"
alias bash_functions="subl ~/bash_functions"

# source ./alias.sh
source ~/bash_functions/bash_setup.sh
source ~/bash_functions/fn_docker.sh
source ~/bash_functions/fn_database.sh
source ~/bash_functions/fn_filesystem.sh
source ~/bash_functions/fn_git.sh
source ~/bash_functions/fn_misc.sh
source ~/bash_functions/fn_networking.sh
source ~/bash_functions/fn_scraper.sh
source ~/bash_functions/fn_ssh.sh
source ~/bash_functions/fn_filesystem.sh

if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
	source ~/bash_functions/fn_windows.sh
fi
