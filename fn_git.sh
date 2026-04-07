
# Function aliases
alias status='git status'
alias ac='autocommit'
alias gr='git_reset'
alias pullr='pull_git_repos'
alias pushr='push_git_repos'
alias rpoa='repoadd'
alias rpod='repodel'
alias rpo='repos'
alias rpoo='reposopen'
alias rpc='reposcheck'
alias gc='gclone'
# alias addr='add_repo'

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


# add_repo() {
#     local repo_path="$1"
#     local json_file="$BASH_FUNCTIONS_DIR/repos.json"

#     # Check if argument was provided
#     if [ -z "$repo_path" ]; then
#         echo "❌ Usage: add_repo <absolute-path-to-repo>"
#         return 1
#     fi

#     # Ensure target dir exists
#     mkdir -p "$(dirname "$json_file")"

#     # Create file if it doesn't exist
#     if [ ! -f "$json_file" ]; then
#         echo "[]" > "$json_file"
#     fi

#     # Clean up input path
#     repo_path=$(realpath "$repo_path" 2>/dev/null)
#     # if [ ! -d "$repo_path/.git" ]; then
#     #     echo "⚠️ $repo_path is not a valid Git repo."
#     #     return 1
#     # fi

#     # Check for duplicate
#     if grep -qF "\"$repo_path\"" "$json_file"; then
#         echo "✅ Repo already exists in repos.json"
#         return 0
#     fi

#     # Insert into JSON array
#     tmp_file=$(mktemp)
#     jq --arg path "$repo_path" '. + [$path]' "$json_file" > "$tmp_file" && mv "$tmp_file" "$json_file"

#     echo "✅ Added $repo_path to $json_file"
# }


repoadd() {
    local repo_path="${1:-.}"  # Default to current directory if no argument
    local json_file="$BASH_FUNCTION_DIR/repos.json"
    local jq_cmd="$BASH_FUNCTION_DIR/jq"

    # Create file if it doesn't exist
    if [ ! -f "$json_file" ]; then
        echo "[]" > "$json_file"
    fi

    # Resolve to absolute path
    if [ ! -e "$repo_path" ]; then
        echo "❌ Path does not exist: $repo_path"
        return 1
    fi

    local abs_path
    abs_path=$(cd "$repo_path" && pwd)

    if [ -z "$abs_path" ]; then
        echo "❌ Failed to resolve path: $repo_path"
        return 1
    fi

    # Check for duplicate
    if grep -qF "\"$abs_path\"" "$json_file"; then
        echo "✅ Path already exists in repos.json: $abs_path"
        return 0
    fi

    # Insert into JSON array
    tmp_file=$(mktemp)
    "$jq_cmd" --arg path "$abs_path" '. + [$path]' "$json_file" > "$tmp_file" && mv "$tmp_file" "$json_file"

    echo "✅ Added to repos.json: $abs_path"
}


repodel() {
    local json_file="$BASH_FUNCTION_DIR/repos.json"
    local jq_cmd="$BASH_FUNCTION_DIR/jq"
    local hard_delete=false

    # Check for hard delete flag
    if [[ "$1" == "--hard" || "$1" == "-h" ]]; then
        hard_delete=true
    fi

    if [ ! -f "$json_file" ]; then
        echo "❌ $json_file not found."
        return 1
    fi

    # Read and parse repo list
    mapfile -t repos < <("$jq_cmd" -r '.[]' "$json_file")

    if [ "${#repos[@]}" -eq 0 ]; then
        echo "📭 No repos found in $json_file."
        return 1
    fi

    echo "📁 Repos in repos.json:"
    for i in "${!repos[@]}"; do
        printf "[%d] %s\n" "$((i + 1))" "${repos[$i]}"
    done

    echo -n "🗑️  Enter number to delete (or 0 to cancel): "
    read -r choice

    if [ "$choice" -eq 0 ]; then
        echo "❌ Cancelled."
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#repos[@]}" ]; then
        echo "❌ Invalid selection."
        return 1
    fi

    local selected="${repos[$((choice - 1))]}"
    local trimmed=$(echo "$selected" | xargs)

    if [ "$hard_delete" = true ]; then
        # Hard delete - remove from JSON and filesystem
        echo
        echo "⚠️⚠️⚠️  WARNING: PERMANENT DELETION ⚠️⚠️⚠️"
        echo "This will DELETE the entire directory from your filesystem:"
        echo "  $trimmed"
        echo
        echo -n "Type 'DELETE' to confirm permanent deletion: "
        read -r hard_confirm

        if [ "$hard_confirm" != "DELETE" ]; then
            echo "❌ Cancelled. Directory was not deleted."
            return 0
        fi

        # Check if directory exists
        if [ -d "$trimmed" ]; then
            echo "🗑️  Deleting directory from filesystem..."
            rm -rf "$trimmed"
            if [ $? -eq 0 ]; then
                echo "✅ Directory deleted: $trimmed"
            else
                echo "❌ Failed to delete directory: $trimmed"
                return 1
            fi
        else
            echo "⚠️  Directory does not exist: $trimmed"
        fi

        # Remove from JSON
        tmp_file=$(mktemp)
        "$jq_cmd" --arg path "$selected" 'map(select(. != $path))' "$json_file" > "$tmp_file" && mv "$tmp_file" "$json_file"
        echo "✅ Removed from repos.json: $selected"
    else
        # Soft delete - remove from JSON only
        echo "⚠️  About to remove from repos.json: $selected"
        echo -n "Are you sure? (y/n): "
        read -r confirm

        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo "❌ Cancelled."
            return 0
        fi

        tmp_file=$(mktemp)
        "$jq_cmd" --arg path "$selected" 'map(select(. != $path))' "$json_file" > "$tmp_file" && mv "$tmp_file" "$json_file"
        echo "✅ Removed from repos.json: $selected"
    fi
}

reposopen(){
    cd ~/repos
    # If e
    if [ "$1" == "e" ]; then
        open .
    fi
}

repos() {
    if [[ "$1" == "-h" ]]; then
        cd ~/repos
        return 0
    fi

    local json_file="$BASH_FUNCTIONS_DIR/repos.json"
    # local jq="jq.exe"

    if [ ! -f "$json_file" ]; then
        echo "❌ $json_file not found."
        return 1
    fi

    # Read and parse repo list
    mapfile -t repos < <($BASH_FUNCTIONS_DIR/jq -r '.[]' "$json_file")

    if [ "${#repos[@]}" -eq 0 ]; then
        echo "📭 No repos found in $json_file."
        return 1
    fi

    echo "📁 Available Repos:"
    for i in "${!repos[@]}"; do
        printf "[%d] %s\n" "$((i + 1))" "${repos[$i]}"
    done

    echo -n "🔢 Enter a number to cd into that repo: "
    read -r choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#repos[@]}" ]; then
        echo "❌ Invalid selection."
        return 1
    fi

    local selected="${repos[$((choice - 1))]}"
    echo $selected
    trimmed=$(echo "$selected" | xargs)
    # if [ -d "$selected" ]; then
    echo "📂 Changing directory to: $selected"
    cd $trimmed # || return 1
    # else
    #     echo "⚠️ Directory does not exist: $selected"
    #     return 1
    # fi
}

reposcheck() {
    local json_file="$BASH_FUNCTIONS_DIR/repos.json"
    local worktrees_json="$BASH_FUNCTIONS_DIR/worktrees.json"
    local jq="$BASH_FUNCTIONS_DIR/jq"

    echo "🔍 Checking Git status for each repo..."

    # Check repos from repos.json
    if [ -f "$json_file" ]; then
        mapfile -t repos < <($jq -r '.[]' "$json_file")
        
        for repo in "${repos[@]}"; do
            repo=$(echo "$repo" | xargs)
            cd "$repo" || continue
            if [[ -n $(git status --porcelain) ]]; then
                echo "❌ Changes: $repo"
            else
                echo "✅ Clean:   $repo"
            fi
        done
    fi

    # Check worktrees from worktrees.json
    if [ -f "$worktrees_json" ]; then
        mapfile -t worktrees < <($jq -r '.[]' "$worktrees_json")
        
        for worktree in "${worktrees[@]}"; do
            worktree=$(echo "$worktree" | xargs)
            if [ ! -d "$worktree" ]; then
                continue
            fi
            cd "$worktree" || continue
            if [[ -n $(git status --porcelain) ]]; then
                echo "❌ Changes: $worktree"
            else
                echo "✅ Clean:   $worktree"
            fi
        done
    fi
}

gclone() {
    local git_url="$1"
    local custom_name="$2"
    local repos_dir="$HOME/repos"
    local json_file="$BASH_FUNCTIONS_DIR/repos.json"
    local jqlocal="$BASH_FUNCTIONS_DIR/jq"  # or just "jq" if it's in your PATH

    # Check if git URL was provided
    if [ -z "$git_url" ]; then
        echo "❌ Usage: git_clone_repo <git-url> [custom-name]"
        echo "   Example: git_clone_repo https://github.com/user/repo.git"
        echo "   Example: git_clone_repo https://github.com/user/repo.git my-custom-name"
        return 1
    fi

    # Create repos directory if it doesn't exist
    mkdir -p "$repos_dir"

    # Extract repo name from git URL if custom name not provided
    local repo_name
    if [ -n "$custom_name" ]; then
        repo_name="$custom_name"
    else
        # Extract name from URL (e.g., https://github.com/user/repo.git -> repo)
        repo_name=$(basename "$git_url" .git)
    fi

    local target_path="$repos_dir/$repo_name"

    # Check if directory already exists
    if [ -d "$target_path" ]; then
        echo "⚠️  Directory already exists: $target_path"
        return 1
    fi

    # Clone the repository
    echo "📥 Cloning $git_url into $target_path..."
    if git clone "$git_url" "$target_path"; then
        echo "✅ Successfully cloned repository"
        
        # Add to repos.json
        # Create file if it doesn't exist
        if [ ! -f "$json_file" ]; then
            echo "[]" > "$json_file"
        fi

        # Get absolute path in Git Bash format (/c/Users/...)
        local abs_path
        abs_path=$(cd "$target_path" && pwd)

        # Check for duplicate
        if grep -qF "\"$abs_path\"" "$json_file"; then
            echo "ℹ️  Repo already in repos.json"
        else
            # Insert into JSON array
            tmp_file=$(mktemp)
            "$jqlocal" --arg path "$abs_path" '. + [$path]' "$json_file" > "$tmp_file" && mv "$tmp_file" "$json_file"
            echo "✅ Added $abs_path to repos.json"
        fi

        echo "📂 Repository location: $target_path"
        return 0
    else
        echo "❌ Failed to clone repository"
        return 1
    fi
}

alias repos_edit="$EDITOR $BASH_FUNCTIONS_DIR/repos.json"
alias gitlog="git log --oneline"

alias lazygit_install="$BASH_FUNCTIONS_DIR/apps/lazygit/install_lazygit.sh"

# Lazygit function - uses locally installed lazygit if available
lazygit() {
    local LAZYGIT_BIN="$BASH_FUNCTIONS_DIR/apps/lazygit/bin/lazygit"
    local LAZYGIT_EXE="$BASH_FUNCTIONS_DIR/apps/lazygit/bin/lazygit.exe"
    
    if [ -f "$LAZYGIT_EXE" ]; then
        "$LAZYGIT_EXE" "$@"
    elif [ -f "$LAZYGIT_BIN" ]; then
        "$LAZYGIT_BIN" "$@"
    elif command -v lazygit &> /dev/null; then
        echo "ℹ️  Using system lazygit (local version not found)"
        lazygit "$@"
    else
        echo "❌ lazygit not found!"
        echo "Run: $BASH_FUNCTIONS_DIR/apps/lazygit/install_lazygit.sh"
        return 1
    fi
}

alias lg='lazygit'

worktree() {
    local action="$1"
    local branch_name="$2"
    local nested=false
    local worktrees_json="$BASH_FUNCTIONS_DIR/worktrees.json"
    local jq_cmd="$BASH_FUNCTIONS_DIR/jq"

    # Check for --nested flag
    if [[ "$2" == "--nested" || "$2" == "-n" ]]; then
        nested=true
        branch_name="$3"
    elif [[ "$3" == "--nested" || "$3" == "-n" ]]; then
        nested=true
    fi

    if [ -z "$action" ]; then
        echo "Usage: worktree <add|remove|change|pull|list> <branchname> [--nested|-n]"
        echo ""
        echo "Actions:"
        echo "  add      - Create a new worktree for a branch"
        echo "  remove   - Remove an existing worktree"
        echo "  change   - Change directory to a worktree"
        echo "  pull     - Pull changes for the current worktree's branch"
        echo "  list     - List all worktrees"
        echo ""
        echo "Flags:"
        echo "  --nested, -n  - Use nested directory structure (e.g., feat/branch instead of feat-branch)"
        return 1
    fi

    # Check if we're in a git repository
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Error: Not inside a git repository."
        return 1
    fi

    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [ -z "$repo_root" ]; then
        echo "❌ Error: Could not determine repository root."
        return 1
    fi

    local parent_dir
    parent_dir=$(dirname "$repo_root")
    
    # Determine directory structure based on nested flag
    local target_dir
    if [ "$nested" = true ]; then
        # Nested structure: preserve the / in the path
        target_dir="$parent_dir/$branch_name"
    else
        # Flat structure: replace / with -
        local dir_name="${branch_name//\//-}"
        target_dir="$parent_dir/$dir_name"
    fi

    case "$action" in
        add)
            if [ -z "$branch_name" ]; then
                echo "❌ Error: branchname is required for add"
                return 1
            fi
            echo "➕ Adding worktree for branch '$branch_name' at '$target_dir'..."
            if git worktree add "$target_dir" "$branch_name"; then
                # Create worktrees.json if it doesn't exist
                if [ ! -f "$worktrees_json" ]; then
                    echo "[]" > "$worktrees_json"
                fi
                
                # Get absolute path
                local abs_path
                abs_path=$(cd "$target_dir" && pwd)
                
                # Add to worktrees.json
                if ! grep -qF "\"$abs_path\"" "$worktrees_json"; then
                    tmp_file=$(mktemp)
                    "$jq_cmd" --arg path "$abs_path" '. + [$path]' "$worktrees_json" > "$tmp_file" && mv "$tmp_file" "$worktrees_json"
                    echo "✅ Added to worktrees.json"
                fi
            fi
            ;;
        remove)
            if [ -z "$branch_name" ]; then
                echo "❌ Error: branchname is required for remove"
                return 1
            fi
            if [ ! -d "$target_dir" ]; then
                echo "❌ Error: Worktree directory '$target_dir' does not exist."
                return 1
            fi
            read -p "⚠️ Are you sure you want to remove the worktree for '$branch_name' at '$target_dir'? (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                # Get absolute path before removing
                local abs_path
                abs_path=$(cd "$target_dir" && pwd)
                
                if git worktree remove "$target_dir"; then
                    echo "✅ Worktree removed."
                    
                    # Remove from worktrees.json
                    if [ -f "$worktrees_json" ]; then
                        tmp_file=$(mktemp)
                        "$jq_cmd" --arg path "$abs_path" 'map(select(. != $path))' "$worktrees_json" > "$tmp_file" && mv "$tmp_file" "$worktrees_json"
                        echo "✅ Removed from worktrees.json"
                    fi
                fi
            else
                echo "❌ Removal cancelled."
            fi
            ;;
        change)
            if [ -z "$branch_name" ]; then
                echo "❌ Error: branchname is required for change"
                return 1
            fi
            if [ -d "$target_dir" ]; then
                echo "📂 Changing to worktree: $target_dir"
                cd "$target_dir" || echo "❌ Failed to change directory."
            else
                # Fallback: check if it's listed in git worktree list
                local wt_path
                wt_path=$(git worktree list | grep "\[$branch_name\]" | awk '{print $1}')
                if [ -n "$wt_path" ] && [ -d "$wt_path" ]; then
                    echo "📂 Changing to worktree: $wt_path"
                    cd "$wt_path" || echo "❌ Failed to change directory."
                else
                    echo "❌ Error: Worktree directory '$target_dir' does not exist."
                    return 1
                fi
            fi
            ;;
        pull)
            # Pull changes for the current worktree's branch
            local current_branch
            current_branch=$(git branch --show-current 2>/dev/null)
            
            if [ -z "$current_branch" ]; then
                echo "❌ Error: Could not determine current branch."
                return 1
            fi
            
            echo "🔄 Pulling changes for branch '$current_branch'..."
            git pull origin "$current_branch"
            ;;
        list)
            git worktree list
            ;;
        *)
            echo "❓ Unknown action: $action"
            echo "Usage: worktree <add|remove|change|pull|list> <branchname> [--nested|-n]"
            return 1
            ;;
    esac
}

greauth(){
   git config --global credential.helper manager
   git fetch 
}