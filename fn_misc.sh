alias nvm_ls="nvm ls"

migration_date() {
  # Y_m_d_His
  local dt=$(date '+%Y_%m_%d_%H%M%S');
  echo "$dt"
}

folder_date() {
  local dt=$(date '+%d_%m_%Y_%H%M%S');
  echo "$dt"
}

generate_string() {
    local length=${1:-16}  # Default to 16 if no length is provided
    local encoding=${2:-hex}  # Default to hex if no encoding is provided

    if [[ "$encoding" == "hex" ]]; then
        local password=$(openssl rand -hex $((length / 2)))  # Hex uses 2 chars per byte
    elif [[ "$encoding" == "base64" ]]; then
        local password=$(openssl rand -base64 $length | tr -d '=+/')  # Trim special chars
    else
        echo "Invalid encoding type! Use 'hex' or 'base64'."
        return 1
    fi

    echo "$password"
}
# generate_string 32 base64
# generate_string 20 hex
