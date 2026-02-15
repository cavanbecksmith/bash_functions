
# ====== NETWORKING

# Example usage LINUX / WIN
# scp_upload ssh_entry "C:\path\to\local\file.txt" "/path/to/remote/directory/"
# scp_upload ssh_entry "/path/to/local/file.txt" "C:/path/to/remote/directory/"

find_largest_dirs() {
  local PATH_TO_SCAN="${1:-/}"

  echo "Scanning: $PATH_TO_SCAN"
  echo ""
  echo "Top 20 largest directories (depth = 2):"
  echo "----------------------------------------"

  sudo du -h --max-depth=2 "$PATH_TO_SCAN" 2>/dev/null | sort -hr | head -n 20
}


set_permissions() {
    local target_directory=$1

    if [ -z "$target_directory" ]; then
        echo "Usage: set_permissions <directory>"
        return 1
    fi

    if [ ! -d "$target_directory" ]; then
        echo "Error: $target_directory is not a directory."
        return 1
    fi

    find "$target_directory" -type d -exec chmod 755 {} \;
    find "$target_directory" -type f -exec chmod 644 {} \;

    echo "Permissions set to 755 for directories and 644 for files in $target_directory"
}

set_wp_permissions_strict() {
    local target_directory=$1
    local web_group="www-data" 

    if [ -z "$target_directory" ]; then
        echo "Usage: set_wp_permissions <directory>"
        return 1
    fi

    if [ ! -d "$target_directory" ]; then
        echo "Error: $target_directory is not a directory."
        return 1
    fi

    echo "Starting STRICT permission hardening on $target_directory..."

    # 1. Ensure the group ownership is correct
    # This is vital so FileBrowser and WP share access
    chgrp -R "$web_group" "$target_directory"

    # 2. Directories: 2770 
    # (2) SetGID: New files inherit the www-data group
    # (7) Owner: Read/Write/Execute
    # (7) Group: Read/Write/Execute
    # (0) Others: No access at all
    find "$target_directory" -type d -exec chmod 2770 {} \;

    # 3. Files: 660
    # (6) Owner: Read/Write
    # (6) Group: Read/Write
    # (0) Others: No access at all
    find "$target_directory" -type f -exec chmod 660 {} \;

    # 4. Special handling for wp-config.php
    # Already covered by 660, but explicitly ensuring it stays that way
    if [ -f "$target_directory/wp-config.php" ]; then
        chmod 660 "$target_directory/wp-config.php"
        echo "Confirmed wp-config.php is 660."
    fi

    echo "Permissions successfully set to 770/660."
    echo "Note: If you see '403 Forbidden', ensure your Web Server user is in the $web_group group."
}


scp_upload() {
    if [ "$#" -ne 3 ]; then
        echo "Usage: scp_upload <ssh_entry> <local_file_path> <remote_directory>"
        return 1
    fi
    ssh_entry=$1
    local_file_path=$2
    remote_directory=$3
    # Check if the script is running on Windows (Git Bash, Cygwin, WSL)
    if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
        # Escape backslashes in the Windows path
        local_file_path=$(echo "$local_file_path" | sed 's/\\/\//g')
    fi
    # Execute the scp command
    scp "$local_file_path" "$ssh_entry":"$remote_directory"
    # Check if the scp command was successful
    if [ "$?" -eq 0 ]; then
        echo "File uploaded successfully to $ssh_entry:$remote_directory"
    else
        echo "File upload failed"
        return 1
    fi
}


sftp_upload() {
  #----------------------------------------------------------
  # sftp_upload
  #
  # Uploads a file or directory to a remote server via SFTP
  # using a host defined in your SSH config (~/.ssh/config).
  #
  # Usage:
  #   sftp_upload <host> <source> <destination>
  #
  # Example:
  #   sftp_upload myserver ./index.html /var/www/html/
  #
  # Notes:
  #   - The host must be defined in your SSH config.
  #   - Creates the remote directory if it doesn’t exist.
  #   - Supports single file and recursive directory uploads.
  #----------------------------------------------------------

  local host="$1"
  local src="$2"
  local dest="$3"

  # Help
  if [[ "$1" == "-h" || "$1" == "--help" || -z "$host" || -z "$src" || -z "$dest" ]]; then
    echo "Usage: sftp_upload <host> <source> <destination>"
    echo "Example: sftp_upload myserver ./index.html /var/www/html/"
    return 0
  fi

  # Check source
  [[ ! -e "$src" ]] && echo "Source not found." && return 1

  # Ensure remote directory exists
  ssh -o StrictHostKeyChecking=no "$host" "mkdir -p '$dest'" || return 1

  # Upload
  sftp -o StrictHostKeyChecking=no "$host" <<< $"put -r $src $dest" || return 1

  echo "Done."
}
