
function autocommit() {
	git add --all
	git commit -m "AUTO COMMIT"
	git push
}

function git_reset(){
    read -p "Sure u want to reset commits? (y/n): " response
if [[ "$response" == "y" || "$response" == "Y" ]]; then
  git reset --hard HEAD
else
    echo "goodbye"
fi

}


pull_git_repos() {
    local json_file="$HOME/bash_functions/repos.json"   

    # Create the file if it doesn't exist
    if [ ! -f "$json_file" ]; then
        echo "[]" > "$json_file"
        echo "Created $json_file with empty array."
        return 0
    fi

    # Read and sanitize the file (very simple JSON parser for flat string array)
    local raw_content
    raw_content=$(<"$json_file")
    
    # Remove brackets, quotes, and whitespace, then split by commas
    raw_content=${raw_content//[/}
    raw_content=${raw_content//]/}
    raw_content=${raw_content//\"/}
    raw_content=$(echo "$raw_content" | tr -d ' \t\n\r')

    IFS=',' read -ra folders <<< "$raw_content"

    if [ ${#folders[@]} -eq 0 ] || [ -z "${folders[0]}" ]; then
        echo "No folders found in $json_file."
        return 0
    fi

    # Loop and pull repos
    for folder in "${folders[@]}"; do
        if [ -d "$folder/.git" ]; then
            echo "Pulling in $folder..."
            git -C "$folder" pull
        else
            echo "Skipping $folder – not a Git repo."
        fi
    done
}


push_git_repos() {
    local json_file="$HOME/bash_functions/repos.json"

    if [ ! -f "$json_file" ]; then
        echo "$json_file not found."
        return 1
    fi

    # Read and sanitize the file
    local raw_content
    raw_content=$(<"$json_file")
    raw_content=${raw_content//[/}
    raw_content=${raw_content//]/}
    raw_content=${raw_content//\"/}
    raw_content=$(echo "$raw_content" | tr -d ' \t\n\r')

    IFS=',' read -ra folders <<< "$raw_content"

    if [ ${#folders[@]} -eq 0 ] || [ -z "${folders[0]}" ]; then
        echo "No folders found in $json_file."
        return 1
    fi

    for folder in "${folders[@]}"; do
        if [ -d "$folder/.git" ]; then
            echo
            echo "🔍 Checking $folder..."
            git -C "$folder" status

            while true; do
                echo -n "Do you want to push changes in $folder? (y=push / n=skip / d=diff): "
                read -r answer
                case "$answer" in
                    [Yy])
                        git -C "$folder" push
                        break
                        ;;
                    [Nn])
                        echo "⏩ Skipped $folder"
                        break
                        ;;
                    [Dd])
                        echo "🔎 Diff for $folder:"
                        git -C "$folder" diff
                        ;;
                    *)
                        echo "❓ Invalid choice. Please enter y, n, or d."
                        ;;
                esac
            done
        else
            echo "⚠️ Skipping $folder – not a Git repo."
        fi
    done
}


add_repo() {
    local repo_path="$1"
    local json_file="$BASH_FUNCTIONS_DIR/repos.json"

    # Check if argument was provided
    if [ -z "$repo_path" ]; then
        echo "❌ Usage: add_repo <absolute-path-to-repo>"
        return 1
    fi

    # Ensure target dir exists
    mkdir -p "$(dirname "$json_file")"

    # Create file if it doesn't exist
    if [ ! -f "$json_file" ]; then
        echo "[]" > "$json_file"
    fi

    # Clean up input path
    repo_path=$(realpath "$repo_path" 2>/dev/null)
    if [ ! -d "$repo_path/.git" ]; then
        echo "⚠️ $repo_path is not a valid Git repo."
        return 1
    fi

    # Check for duplicate
    if grep -qF "\"$repo_path\"" "$json_file"; then
        echo "✅ Repo already exists in repos.json"
        return 0
    fi

    # Insert into JSON array
    tmp_file=$(mktemp)
    jq --arg path "$repo_path" '. + [$path]' "$json_file" > "$tmp_file" && mv "$tmp_file" "$json_file"

    echo "✅ Added $repo_path to $json_file"
}