BASH_FUNCTION_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

generate_env_file() {
    echo "Generating .env file..."
    read -p "Enter a value for HOME_DIRECTORY (Leave Empty for Auto Select Directory): " home_dir
    read -p "Enter a value for APP_ENV (e.g., development, production): " app_env
    read -p "Enter a value for CUSTOM_ENTRYPOINT (/root/entrypoint.sh): " entrypoint
    read -p "Enter a value for code editor (e.g code, nano): " editor
    current_user="$USER"
    if [[ -z "$home_dir" ]]; then
        if [[ "$OSTYPE" == "linux-gnu"* ]]; then
            home_dir="/home/$current_user"
        elif [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* ]]; then        
            if [[ -z "$current_user" ]]; then 
                current_user="$USERNAME"
            fi
            home_dir="C://Users/$current_user"
        fi
        SSH_PATH="$home_dir/.ssh"
    else
        SSH_PATH="$home_dir/.ssh"
    fi
    echo "$home_dir"
    env_file="$home_dir/bash_functions/.env"
    cat <<EOL > "$env_file"
# Generated environment variables
SSH_PATH="$SSH_PATH"
APP_ENV="$app_env"
OS="${OSTYPE}"
USER="$current_user"
HOME_DIRECTORY="$home_dir"
CUSTOM_ENTRYPOINT="$entrypoint"
EDITOR="$editor"
EOL
    echo ".env file generated successfully."
}

jq_install() {
    if [ -z "$BASH_FUNCTIONS_DIR" ]; then
        echo "❌ BASH_FUNCTIONS_DIR is not set."
        return 1
    fi

    local jq_version="jq-1.7"
    local uname_os uname_arch platform output_name

    uname_os=$(uname -s)
    uname_arch=$(uname -m)
    output_name="jq"

    # Determine correct platform
    case "$uname_os" in
        Linux)
            platform="jq-linux64"
            ;;
        Darwin)
            platform="jq-osx-amd64"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            platform="jq-win64.exe"
            output_name="jq.exe"
            ;;
        *)
            echo "❌ Unsupported OS: $uname_os"
            return 1
            ;;
    esac

    local install_path="$BASH_FUNCTIONS_DIR/$output_name"
    local url="https://github.com/jqlang/jq/releases/download/${jq_version}/${platform}"

    echo "⬇️ Downloading jq to $install_path..."
    mkdir -p "$BASH_FUNCTIONS_DIR"
    curl -L "$url" -o "$install_path" || { echo "❌ Download failed."; return 1; }

    chmod +x "$install_path"
    echo "✅ jq installed to $install_path"
    echo "ℹ️ Run with: $install_path --version"
}



load_env_file() {
    source "$BASH_FUNCTION_DIR/.env"
    if [[ "$CUSTOM_ENTRYPOINT" != "" ]]; then
        source "$CUSTOM_ENTRYPOINT"
    fi
}

env_settings() {
    echo "Current OS: $OS"
    echo "Current User: $USER"
    echo "SSH_PATH: $SSH_PATH"
    echo "APP_ENV: $APP_ENV"
}

load_env_file
# env_settings
