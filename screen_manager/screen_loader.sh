#!/bin/bash

# Screen Session Manager Function
# A single bash function that manages screen sessions based on JSON configuration
# 
# Usage: 
#   screen_manager                    # Interactive mode
#   screen_manager <screen_name>      # Load specific screen
#   screen_manager --list             # List available configurations
#   screen_manager --status           # Show running sessions
#   screen_manager --help             # Show help

screen_manager() {
    # Configuration - adjust these paths as needed
    local SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local PYTHON_HELPER="$SCRIPT_DIR/screen_manager.py"
    local CONFIG_FILE="$SCRIPT_DIR/screen_configs.json"
    
    # Colors for output
    local RED='\033[0;31m'
    local GREEN='\033[0;32m'
    local YELLOW='\033[1;33m'
    local BLUE='\033[0;34m'
    local NC='\033[0m' # No Color
    
    # Function to print colored output
    print_color() {
        local color=$1
        shift
        echo -e "${color}$*${NC}"
    }
    
    # Function to get the correct Python command
    get_python_command() {
        if command -v python3 &> /dev/null; then
            echo "python3"
        elif command -v python &> /dev/null; then
            echo "python"
        else
            return 1
        fi
    }
    
    # Function to check if required files exist
    check_dependencies() {
        local skip_screen_check="${1:-false}"
        
        if [[ ! -f "$PYTHON_HELPER" ]]; then
            print_color $RED "Error: Python helper script not found at $PYTHON_HELPER"
            return 1
        fi
        
        if [[ ! -f "$CONFIG_FILE" ]]; then
            print_color $RED "Error: Configuration file not found at $CONFIG_FILE"
            return 1
        fi
        
        # Check if Python is available
        if ! command -v python3 &> /dev/null && ! command -v python &> /dev/null; then
            print_color $RED "Error: Python is required but not found"
            return 1
        fi
        
        # Check if screen is available (unless we're testing)
        if [[ "$skip_screen_check" != "true" ]] && ! command -v screen &> /dev/null; then
            print_color $RED "Error: GNU screen is required but not found"
            print_color $YELLOW "Please install screen:"
            print_color $YELLOW "  Windows (WSL): sudo apt-get install screen"
            print_color $YELLOW "  Windows (Cygwin): apt-cyg install screen"
            print_color $YELLOW "  macOS: brew install screen"
            print_color $YELLOW "  Ubuntu/Debian: sudo apt-get install screen"
            print_color $YELLOW ""
            print_color $YELLOW "Or use --test to test the menu without screen:"
            print_color $YELLOW "  screen_manager --test"
            return 1
        fi
    }
    
    # Function to get available screens
    get_available_screens() {
        local python_cmd=$(get_python_command)
        local output
        output=$($python_cmd "$PYTHON_HELPER" list 2>&1)
        
        if [[ $? -ne 0 ]]; then
            print_color $RED "Error getting screen list: $output"
            return 1
        fi
        
        # Extract screen names (after the __SCREEN_NAMES__ marker)
        echo "$output" | sed -n '/__SCREEN_NAMES__/,$p' | tail -n +2
    }
    
    # Function to display menu and get user choice
    show_menu() {
        print_color $BLUE "=== Screen Session Manager ==="
        echo
        
        # Get and display available screens
        local python_cmd=$(get_python_command)
        local screens_output
        screens_output=$($python_cmd "$PYTHON_HELPER" list 2>&1)
        
        if [[ $? -ne 0 ]]; then
            print_color $RED "Error: $screens_output"
            return 1
        fi
        
        # Show the descriptive list
        echo "$screens_output" | sed '/__SCREEN_NAMES__/,$d'
        
        # Get screen names for selection
        local screen_names
        screen_names=($(get_available_screens))
        
        if [[ ${#screen_names[@]} -eq 0 ]]; then
            print_color $RED "No screen configurations found!"
            return 1
        fi
        
        echo
        print_color $YELLOW "Enter the number or name of the screen you want to load:"
        print_color $YELLOW "Or press Ctrl+C to exit"
        echo
        
        read -p "Your choice: " choice
        
        # Validate choice
        if [[ "$choice" =~ ^[0-9]+$ ]]; then
            # Numeric choice
            if [[ "$choice" -ge 1 && "$choice" -le ${#screen_names[@]} ]]; then
                selected_screen="${screen_names[$((choice-1))]}"
            else
                print_color $RED "Invalid choice: $choice. Please enter a number between 1 and ${#screen_names[@]}"
                return 1
            fi
        else
            # Name choice - check if it exists
            selected_screen="$choice"
            local found=false
            for screen in "${screen_names[@]}"; do
                if [[ "$screen" == "$selected_screen" ]]; then
                    found=true
                    break
                fi
            done
            
            if [[ "$found" == false ]]; then
                print_color $RED "Invalid screen name: $selected_screen"
                print_color $YELLOW "Available screens: ${screen_names[*]}"
                return 1
            fi
        fi
        
        echo "$selected_screen"
    }
    
    # Function to check if a screen session exists
    screen_exists() {
        local screen_name=$1
        local python_cmd=$(get_python_command)
        local result
        result=$($python_cmd "$PYTHON_HELPER" exists "$screen_name" 2>&1)
        
        if [[ $? -ne 0 ]]; then
            print_color $RED "Error checking screen existence: $result"
            return 1
        fi
        
        [[ "$result" == "yes" ]]
    }
    
    # Function to create and start a new screen session
    create_screen() {
        local screen_name=$1
        
        print_color $BLUE "Creating new screen session: $screen_name"
        
        # Generate screenrc file
        local python_cmd=$(get_python_command)
        local screenrc_path
        screenrc_path=$($python_cmd "$PYTHON_HELPER" create "$screen_name" 2>&1)
        
        if [[ $? -ne 0 ]]; then
            print_color $RED "Error creating screen configuration: $screenrc_path"
            return 1
        fi
        
        # Debug: show the generated screenrc content
        print_color $YELLOW "Generated screenrc at: $screenrc_path"
        if [[ -f "$screenrc_path" ]]; then
            print_color $YELLOW "Screenrc content:"
            cat "$screenrc_path"
            echo
        fi
        
        # Start screen with the generated configuration in detached mode, then attach
        print_color $BLUE "Creating detached screen session..."
        if screen -d -m -S "$screen_name" -c "$screenrc_path"; then
            print_color $GREEN "Screen session created successfully"
        else
            print_color $RED "Failed to create screen session"
            return 1
        fi
        
        # Give screen a moment to start up
        sleep 2
        
        # Check if the session was actually created
        if screen -list | grep -q "$screen_name"; then
            print_color $GREEN "Session '$screen_name' is running"
        else
            print_color $RED "Session '$screen_name' was not created properly"
            screen -list
            return 1
        fi
        
        # Clean up temporary screenrc file
        rm -f "$screenrc_path" 2>/dev/null || true
        
        # Now attach to the session
        print_color $GREEN "Attaching to screen session: $screen_name"
        screen -r "$screen_name"
    }
    
    # Function to attach to existing screen session
    attach_screen() {
        local screen_name=$1
        
        print_color $GREEN "Attaching to existing screen session: $screen_name"
        screen -r "$screen_name"
    }
    
    # Function to handle screen session
    manage_screen() {
        local screen_name=$1
        
        if screen_exists "$screen_name"; then
            print_color $YELLOW "Screen session '$screen_name' already exists."
            echo "What would you like to do?"
            echo "1. Attach to existing session"
            echo "2. Create new session (will detach existing)"
            echo "3. List existing sessions"
            echo "4. Cancel"
            
            read -p "Your choice (1-4): " action_choice
            
            case $action_choice in
                1)
                    attach_screen "$screen_name"
                    ;;
                2)
                    print_color $YELLOW "Detaching existing session..."
                    screen -S "$screen_name" -X quit 2>/dev/null || true
                    sleep 1
                    create_screen "$screen_name"
                    ;;
                3)
                    print_color $BLUE "Existing screen sessions:"
                    screen -list
                    echo
                    print_color $YELLOW "Use 'screen -r <session_name>' to attach manually"
                    ;;
                4)
                    print_color $BLUE "Cancelled."
                    return 0
                    ;;
                *)
                    print_color $RED "Invalid choice: $action_choice"
                    return 1
                    ;;
            esac
        else
            create_screen "$screen_name"
        fi
    }
    
    # Function to display help
    show_help() {
        echo "Screen Session Manager Function"
        echo
        echo "Usage: screen_manager [OPTION] [SCREEN_NAME]"
        echo
        echo "Options:"
        echo "  -h, --help     Show this help message"
        echo "  -l, --list     List available screen configurations"
        echo "  -s, --status   Show status of all screen sessions"
        echo "  -t, --test     Test mode - show menu without screen dependency"
        echo
        echo "Arguments:"
        echo "  SCREEN_NAME    Name of the screen to load (optional, will prompt if not provided)"
        echo
        echo "Examples:"
        echo "  screen_manager                    # Interactive mode - shows menu"
        echo "  screen_manager development        # Load 'development' screen directly"
        echo "  screen_manager --list            # List all available configurations"
        echo "  screen_manager --status          # Show running screen sessions"
        echo "  screen_manager --test            # Test the menu without screen installed"
    }
    
    # Main function logic
    # Parse command line arguments
    case "${1:-}" in
        -h|--help)
            show_help
            return 0
            ;;
        -l|--list)
            check_dependencies || return 1
            python_cmd=$(get_python_command)
            $python_cmd "$PYTHON_HELPER" list
            return 0
            ;;
        -s|--status)
            check_dependencies || return 1
            print_color $BLUE "Current screen sessions:"
            screen -list || print_color $YELLOW "No screen sessions running"
            return 0
            ;;
        -t|--test)
            check_dependencies true || return 1
            print_color $YELLOW "=== TEST MODE - Screen not required ==="
            screen_name=$(show_menu)
            if [[ $? -eq 0 ]]; then
                print_color $GREEN "Selected screen: $screen_name"
                print_color $YELLOW "In normal mode, this would create/attach to the '$screen_name' screen session"
            fi
            return 0
            ;;
        -*)
            print_color $RED "Unknown option: $1"
            echo "Use -h or --help for usage information"
            return 1
            ;;
    esac
    
    # Check dependencies
    check_dependencies || return 1
    
    # Determine screen name
    local screen_name
    if [[ -n "${1:-}" ]]; then
        # Screen name provided as argument
        screen_name="$1"
        
        # Validate that this screen exists in configuration
        local available_screens
        available_screens=($(get_available_screens))
        local found=false
        
        for screen in "${available_screens[@]}"; do
            if [[ "$screen" == "$screen_name" ]]; then
                found=true
                break
            fi
        done
        
        if [[ "$found" == false ]]; then
            print_color $RED "Error: Screen configuration '$screen_name' not found"
            print_color $YELLOW "Available screens: ${available_screens[*]}"
            return 1
        fi
    else
        # Interactive mode
        screen_name=$(show_menu)
        [[ $? -eq 0 ]] || return 1
    fi
    
    # Manage the screen session
    manage_screen "$screen_name"
}

# If script is executed directly (not sourced), run the function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Trap Ctrl+C for clean exit
    trap 'echo; echo -e "\033[1;33mCancelled by user\033[0m"; exit 130' INT
    
    # Run main function with all arguments
    screen_manager "$@"
fi