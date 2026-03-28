#!/bin/bash

# ====== NOTES

notes() {
    if [[ -z "$NOTES_DIRECTORY" ]]; then
        echo "❌ NOTES_DIRECTORY is not set in .env. Please run generate_env_file."
        return 1
    fi

    case "$1" in
        "obs")
            # URI encode the path for the Obsidian URI
            local path_encoded
            # Replace spaces, slashes, and colons with URI encoded equivalents
            path_encoded=$(echo "$NOTES_DIRECTORY" | sed 's/ /%20/g; s/\//%2F/g; s/:/%3A/g')

            echo "🚀 Opening Obsidian: $NOTES_DIRECTORY"
            
            if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || "$OSTYPE" == "win32" ]]; then
                # Windows: Open using the path parameter
                start "" "obsidian://open?path=$path_encoded"
            elif [[ "$OSTYPE" == "darwin"* ]]; then
                # macOS
                open "obsidian://open?path=$path_encoded"
            else
                # Linux
                if command -v xdg-open >/dev/null 2>&1; then
                    xdg-open "obsidian://open?path=$path_encoded"
                else
                    echo "❌ xdg-open not found. Please open manually or install xdg-utils."
                    return 1
                fi
            fi
            ;;
        "g")
            if [[ ! -d "$NOTES_DIRECTORY" ]]; then
                # Try to handle Windows style paths in MSYS/Git Bash
                if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
                    local unix_path
                    unix_path=$(cygpath -u "$NOTES_DIRECTORY" 2>/dev/null)
                    if [[ -d "$unix_path" ]]; then
                        cd "$unix_path" && gemini
                        return 0
                    fi
                fi
                echo "❌ Directory not found: $NOTES_DIRECTORY"
                return 1
            fi
            cd "$NOTES_DIRECTORY" && gemini
            ;;
        "ask")
            shift # Remove 'ask' from arguments
            local question="$*"
            if [[ -z "$question" ]]; then
                echo "❌ Please provide a question. Usage: notes ask \"your question\""
                return 1
            fi

            if [[ ! -d "$NOTES_DIRECTORY" ]]; then
                # Try to handle Windows style paths in MSYS/Git Bash
                if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
                    local unix_path
                    unix_path=$(cygpath -u "$NOTES_DIRECTORY" 2>/dev/null)
                    if [[ -d "$unix_path" ]]; then
                        # Run gemini from that directory
                        (cd "$unix_path" && gemini -p "$question")
                        return 0
                    fi
                fi
                echo "❌ Directory not found: $NOTES_DIRECTORY"
                return 1
            fi
            # Run in a subshell so we don't change the current shell's directory
            (cd "$NOTES_DIRECTORY" && gemini -p "$question")
            ;;
        "-h"|"--help")
            echo "Notes Helper Command"
            echo "===================="
            echo "Usage:"
            echo "  notes               - Change directory to your notes folder"
            echo "  notes obs           - Open your notes folder in Obsidian"
            echo "  notes g             - Go to notes folder and start Gemini CLI"
            echo "  notes ask \"query\"    - Ask Gemini a question about your notes"
            echo "  notes -h            - Show this help message"
            echo ""
            echo "Configured Directory: $NOTES_DIRECTORY"
            ;;
        *)
            if [[ ! -d "$NOTES_DIRECTORY" ]]; then
                 # Try to handle Windows style paths in MSYS/Git Bash
                 if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then
                    local unix_path
                    unix_path=$(cygpath -u "$NOTES_DIRECTORY" 2>/dev/null)
                    if [[ -d "$unix_path" ]]; then
                        cd "$unix_path"
                        return 0
                    fi
                 fi
                 echo "❌ Directory not found: $NOTES_DIRECTORY"
                 return 1
            fi
            cd "$NOTES_DIRECTORY"
            ;;
    esac
}
