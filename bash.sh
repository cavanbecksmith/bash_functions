# CORE COMMANDS
alias edit="subl ~/.bashrc && subl ~/bash_functions"
alias editn="nano ~/.bashrc"
alias edit_subl="subl ~/.bashrc"
alias ref=". ~/.bashrc"
alias ..="cd ../"
alias ...="cd ../../"
alias bash_functions="subl ~/bash_functions"

# Get the directory this script is located in
BASH_FUNCTIONS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source each script using an absolute path
# source "$BASH_FUNCTIONS_DIR/alias.sh"
source "$BASH_FUNCTIONS_DIR/bash_setup.sh"
source "$BASH_FUNCTIONS_DIR/fn_docker.sh"
source "$BASH_FUNCTIONS_DIR/fn_database.sh"
source "$BASH_FUNCTIONS_DIR/fn_filesystem.sh"
source "$BASH_FUNCTIONS_DIR/fn_git.sh"
source "$BASH_FUNCTIONS_DIR/fn_linux.sh"
source "$BASH_FUNCTIONS_DIR/fn_misc.sh"
source "$BASH_FUNCTIONS_DIR/fn_networking.sh"
source "$BASH_FUNCTIONS_DIR/fn_scraper.sh"
source "$BASH_FUNCTIONS_DIR/fn_ssh.sh"

# source ./alias.sh
# source ~/bash_functions/bash_setup.sh
# source ~/bash_functions/fn_docker.sh
# source ~/bash_functions/fn_database.sh
# source ~/bash_functions/fn_filesystem.sh
# source ~/bash_functions/fn_git.sh
# source ~/bash_functions/fn_linux.sh
# source ~/bash_functions/fn_misc.sh
# source ~/bash_functions/fn_networking.sh
# source ~/bash_functions/fn_scraper.sh
# source ~/bash_functions/fn_ssh.sh
# source ~/bash_functions/fn_filesystem.sh

if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
	# source ~/bash_functions/fn_windows.sh
	source "$BASH_FUNCTIONS_DIR/fn_windows.sh"
fi
