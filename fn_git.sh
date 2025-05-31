
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
            echo "Checking $folder..."
            git -C "$folder" status

            echo -n "Do you want to commit and push changes in $folder? (y/n): "
            read -r answer
            if [[ "$answer" =~ ^[Yy]$ ]]; then
                git -C "$folder" add .
                git -C "$folder" commit -m "Generic update"
                git -C "$folder" push
            else
                echo "Skipped $folder"
            fi
        else
            echo "Skipping $folder – not a Git repo."
        fi
    done
}
