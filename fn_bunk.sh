#!/bin/bash

# ====== BUNK (The Central Entry Point)

bunk() {
    # If no arguments or help requested
    if [[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]]; then
        _bunk_list_pretty
        return 0
    fi

    local cmd="$1"
    shift

    # Check if the function exists
    if declare -f "$cmd" > /dev/null; then
        "$cmd" "$@"
    else
        echo "❌ Error: Command '$cmd' not found in the library."
        echo "💡 Run 'bunk -h' to see all available commands."
        return 1
    fi
}

_bunk_list_pretty() {
    local fn_dir="$BASH_FUNCTIONS_DIR"
    
    if [ -z "$fn_dir" ]; then
        # Fallback if BASH_FUNCTIONS_DIR is not set
        fn_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    fi

    echo -e "\033[1;35m"
    echo """
    ██████╗ ██╗   ██╗███╗   ██╗██╗  ██╗
    ██╔══██╗██║   ██║████╗  ██║██║ ██╔╝
    ██████╔╝██║   ██║██╔██╗ ██║█████╔╝ 
    ██╔══██╗██║   ██║██║╚██╗██║██╔═██╗ 
    ██████╔╝╚██████╔╝██║ ╚████║██║  ██╗
    ╚═════╝  ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝
    """
    echo -e "\033[0m"
    echo -e "\033[1;36mCentral Command Interface\033[0m"
    echo "=========================================="
    echo -e "Usage: \033[1;33mbunk <command> [args]\033[0m"
    echo ""

    # Loop through all fn_*.sh files
    for file in "$fn_dir"/fn_*.sh; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file" .sh | sed 's/^fn_//')
            
            # Extract function names
            local functions=$(grep -E '^\s*(function\s+)?[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)' "$file" | \
                             sed -E 's/^\s*(function\s+)?([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\).*/\2/' | \
                             grep -v '^_') # Hide internal functions starting with _

            if [ -n "$functions" ]; then
                echo -e "\033[1;32m[$filename]\033[0m"
                # Print functions in a clean, indented list
                echo "$functions" | awk '{printf "  %-25s", $1} NR%3==0 {print ""}'
                echo -e "\n"
            fi
        fi
    done
    
    # Also check node/ folders
    if [ -d "$fn_dir/node" ]; then
         echo -e "\033[1;32m[node]\033[0m"
         local node_functions=$(grep -E '^\s*(function\s+)?[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)' "$fn_dir/node/"*.sh 2>/dev/null | \
                               sed -E 's/.*:([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\).*/\1/' | sort | uniq | grep -v '^_')
         if [ -n "$node_functions" ]; then
             echo "$node_functions" | awk '{printf "  %-25s", $1} NR%3==0 {print ""}'
             echo -e "\n"
         fi
    fi

    echo "=========================================="
    echo -e "💡 Tip: You can run any command directly: \033[1;33mbunk notes\033[0m"
}
