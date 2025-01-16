
# ====== NETWORKING

# Example usage LINUX / WIN
# scp_upload ssh_entry "C:\path\to\local\file.txt" "/path/to/remote/directory/"
# scp_upload ssh_entry "/path/to/local/file.txt" "C:/path/to/remote/directory/"

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
