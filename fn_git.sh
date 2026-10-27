# Function aliases
alias status='git status'
alias ac='autocommit'
alias gr='git_reset'
alias pullr='pull_git_repos'
alias pushr='push_git_repos'
alias rpoa='repoadd'
alias rpod='repodel'
alias rpot='repos_toggle'
alias rpint='rpin_toggle'
alias rpo='repos'
alias rpoo='reposopen'
alias rpc='reposcheck'
alias gc='gclone'
alias rpn='reponew'
alias gfetch='git fetch --all'
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
    local json_file="$BASH_FUNCTIONS_DIR/repos.json"
    local jq_cmd="$BASH_FUNCTIONS_DIR/jq"

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


repos_toggle() {
    local repo_path="${1:-.}"  # Default to current directory if no argument
    local json_file="$BASH_FUNCTIONS_DIR/repos.json"
    local jq_cmd="$BASH_FUNCTIONS_DIR/jq"

    # Create file if it doesn't exist
    if [ ! -f "$json_file" ]; then
        echo "[]" > "$json_file"
    fi

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

    local tmp_file
    tmp_file=$(mktemp)

    if "$jq_cmd" -e --arg path "$abs_path" 'index($path) != null' "$json_file" >/dev/null; then
        # Present -> remove
        "$jq_cmd" --arg path "$abs_path" 'map(select(. != $path))' "$json_file" > "$tmp_file" \
            && mv "$tmp_file" "$json_file"
        echo "🗑️  Removed from repos.json: $abs_path"
        _pins_remove "$abs_path" && echo "📌 Removed matching pin."
    else
        # Absent -> add
        "$jq_cmd" --arg path "$abs_path" '. + [$path]' "$json_file" > "$tmp_file" \
            && mv "$tmp_file" "$json_file"
        echo "✅ Added to repos.json: $abs_path"
    fi

    rm -f "$tmp_file" 2>/dev/null
}


repodel() {
    local json_file="$BASH_FUNCTIONS_DIR/repos.json"
    local jq_cmd="$BASH_FUNCTIONS_DIR/jq"
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
        _pins_remove "$selected" && echo "📌 Removed matching pin."
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
        _pins_remove "$selected" && echo "📌 Removed matching pin."
    fi
}

reposopen(){
    cd ~/repos
    # If e
    if [ "$1" == "e" ]; then
        open .
    fi
}

# ---------------------------------------------------------------------------
# Shared helpers for repos / worktrees / pins
#
# The *_norm / *_key / *_label helpers return via globals rather than command
# substitution: they run in tight loops and forking a subshell per path is
# noticeably slow under Git Bash on Windows.
# ---------------------------------------------------------------------------

_repos_jq() {
    local candidate
    for candidate in "$BASH_FUNCTIONS_DIR/jq" "$BASH_FUNCTIONS_DIR/jq.exe"; do
        [ -x "$candidate" ] && { printf '%s' "$candidate"; return 0; }
    done
    candidate=$(command -v jq 2>/dev/null)
    [ -n "$candidate" ] && { printf '%s' "$candidate"; return 0; }
    return 1
}

# repos.json mixes "/c/Users/..." and "C:/Users/..." forms for the same path,
# so everything is normalised to "C:/Users/..." before being compared.
_repos_norm() {
    local p="${1//\\//}"
    p="${p//$'\r'/}"
    p="${p#"${p%%[![:space:]]*}"}"
    p="${p%"${p##*[![:space:]]}"}"
    if [[ "$p" =~ ^/([a-zA-Z])/(.*)$ ]]; then
        p="${BASH_REMATCH[1]^}:/${BASH_REMATCH[2]}"
    elif [[ "$p" =~ ^([a-zA-Z]):(/.*)$ ]]; then
        p="${BASH_REMATCH[1]^}:${BASH_REMATCH[2]}"
    fi
    [ "${#p}" -gt 1 ] && p="${p%/}"
    _NORM="$p"
}

_repos_key() { _repos_norm "$1"; _KEY="${_NORM,,}"; }

_repos_label() {
    local home
    _repos_norm "$HOME"; home="$_NORM"
    _repos_norm "$1"
    if [ "${_NORM,,}" = "${home,,}" ]; then
        _LABEL="~"
    elif [[ "${_NORM,,}" == "${home,,}"/* ]]; then
        _LABEL="~${_NORM:${#home}}"
    else
        _LABEL="$_NORM"
    fi
}

_repos_read_json() {
    local file="$1"
    [ -f "$file" ] || return 0
    [ -n "$_REPOS_JQ" ] || _REPOS_JQ=$(_repos_jq) || return 1
    # jq.exe emits CRLF on Windows; strip CR so paths compare cleanly. A single
    # jq call doubles as the validity check: it fails on malformed JSON, which
    # is when the compatibility parser below takes over.
    "$_REPOS_JQ" -r '.[]' "$file" 2>/dev/null | tr -d '\r'
    [ "${PIPESTATUS[0]}" -eq 0 ] && return 0
    tr -d '[]\r' < "$file" | tr ',' '\n' |
        sed -E "s/^[[:space:]]*['\"]?//; s/['\"]?[[:space:]]*$//" | sed '/^$/d'
}

_repos_match() {
    [ -z "$2" ] && return 0
    local haystack="${1,,}" needle="${2,,}"
    [[ "$haystack" == *"$needle"* ]]
}

_repos_term_cols() {
    local c="${COLUMNS:-}"
    [[ "$c" =~ ^[0-9]+$ ]] || c=$(tput cols 2>/dev/null)
    [[ "$c" =~ ^[0-9]+$ ]] || c=100
    printf '%s' "$c"
}

# ---------------------------------------------------------------------------
# Pins
#
# pins.json is a flat array of paths, same shape as repos.json/worktrees.json.
# A pin's kind (repo / worktree / unattached) is DERIVED at render time from
# membership of the other two files rather than stored, so a path pinned while
# unattached upgrades itself automatically once it is added with repoadd.
# ---------------------------------------------------------------------------

_pins_read() { _repos_read_json "$BASH_FUNCTIONS_DIR/pins.json"; }

_pins_write() {
    local file="$BASH_FUNCTIONS_DIR/pins.json" jq_cmd tmp
    jq_cmd=$(_repos_jq) || return 1
    tmp=$(mktemp)
    if [ "$#" -eq 0 ]; then
        printf '[]\n' > "$tmp"
    else
        printf '%s\n' "$@" | "$jq_cmd" -R -s 'split("\n") | map(select(length > 0))' > "$tmp"
    fi
    mv "$tmp" "$file"
}

_pins_has() {
    local target p
    _repos_key "$1"; target="$_KEY"
    while IFS= read -r p; do
        _repos_key "$p"
        [ "$_KEY" = "$target" ] && return 0
    done < <(_pins_read)
    return 1
}

_pins_add() {
    _pins_has "$1" && return 1
    local existing=()
    mapfile -t existing < <(_pins_read)
    _repos_norm "$1"
    _pins_write "${existing[@]}" "$_NORM"
}

# Called by repodel / repos_toggle / worktree remove so a removed repo or
# worktree never leaves a dangling pin behind.
_pins_remove() {
    local target p keep=() found=1
    _repos_key "$1"; target="$_KEY"
    while IFS= read -r p; do
        _repos_key "$p"
        if [ "$_KEY" = "$target" ]; then found=0; else keep+=("$p"); fi
    done < <(_pins_read)
    [ "$found" -eq 0 ] || return 1
    _pins_write "${keep[@]}"
}

_pins_kind() {
    local target p
    _repos_key "$1"; target="$_KEY"
    while IFS= read -r p; do
        _repos_key "$p"
        [ "$_KEY" = "$target" ] && { printf 'repo'; return 0; }
    done < <(_repos_read_json "$BASH_FUNCTIONS_DIR/repos.json")
    while IFS= read -r p; do
        _repos_key "$p"
        [ "$_KEY" = "$target" ] && { printf 'worktree'; return 0; }
    done < <(_repos_read_json "$BASH_FUNCTIONS_DIR/worktrees.json")
    printf 'unattached'
}

# ---------------------------------------------------------------------------
# Interactive picker: arrow keys move the highlight, Enter opens, typing a
# number jumps to it. The mouse is used for one thing only — right-clicking an
# entry toggles its pin.
#
# The renderer buffers lines into _LINES instead of printing them, so the
# picker can repaint a scrolling window over a list taller than the terminal.
# ---------------------------------------------------------------------------

_repos_tui_capable() {
    [ "$REPOS_TUI" = "0" ] && return 1
    [ -t 0 ] && [ -t 1 ] || return 1
    [ -e /dev/tty ] || return 1
    [ -z "$TERM" ] && return 1
    [ "$TERM" = "dumb" ] && return 1
    command -v stty >/dev/null 2>&1 || return 1
    return 0
}

# Leaving mouse reporting enabled makes the terminal spew escape codes on every
# click for the rest of the session, and leaving -icanon -echo on makes the
# shell look dead: no echo, no line editing. Every exit path comes through here,
# and it falls back to "stty sane" if the saved state was lost.
_repos_pick_cleanup() {
    [ "$_PICK_RAW_ON" = "1" ] || return 0
    if [ -n "$_PICK_STTY" ]; then
        stty "$_PICK_STTY" 2>/dev/null || stty sane 2>/dev/null
    else
        stty sane 2>/dev/null
    fi
    [ "$_PICK_MOUSE_ON" = "1" ] && printf '\e[?1000l\e[?1002l\e[?1006l' > /dev/tty 2>/dev/null
    _PICK_MOUSE_ON=0
    # _PICK_RAW_ON and _PICK_STTY are deliberately NOT cleared here. A SIGINT
    # can abort the picker after this runs but before it finishes unwinding,
    # which previously left the flag saying "clean" while the tty was still
    # raw. Only the prompt guard, which runs once bash is definitely back at a
    # prompt, is allowed to declare the terminal restored.
    return 0
}

# Last line of defence. An interactive bash aborts the running function on
# SIGINT and does not reliably run the INT trap first, so Ctrl-C could leave
# the terminal in -icanon -echo with no code path left to fix it. bash always
# runs PROMPT_COMMAND before drawing a prompt, so restoring from there covers
# every abnormal exit. Costs one string comparison per prompt when idle.
_repos_prompt_guard() {
    if [ "$_PICK_RAW_ON" = "1" ]; then
        _repos_pick_cleanup
        _PICK_RAW_ON=0
        _PICK_STTY=""
    fi
    return 0
}

case "$PROMPT_COMMAND" in
    *_repos_prompt_guard*) ;;
    *) PROMPT_COMMAND="_repos_prompt_guard${PROMPT_COMMAND:+; $PROMPT_COMMAND}" ;;
esac

_repos_cursor_row() {
    # Sets _CURSOR_ROW, and returns success only if a cursor report was parsed.
    # Not a command substitution: it has to hand back keystrokes via a global.
    _CURSOR_ROW=""
    local pos=""
    printf '\e[6n' > /dev/tty
    # Terminals that ignore DSR would otherwise block the picker forever.
    IFS= read -rsd 'R' -t 0.4 pos 2>/dev/null
    [ -z "$pos" ] && return 1
    # A reply is ESC [ rows ; cols, the trailing R having been the delimiter.
    # Anything typed before it arrives lands in the same buffer, so replay it
    # rather than silently eating those keypresses. If the tail does not match
    # a report at all, the terminal never answered and it is all user input.
    local re=$'^(.*)\e\\[([0-9]+);([0-9]+)$'
    if [[ "$pos" =~ $re ]]; then
        _PICK_PENDING+="${BASH_REMATCH[1]}"
        _CURSOR_ROW="${BASH_REMATCH[2]}"
        return 0
    fi
    _PICK_PENDING+="$pos"
    return 1
}

_repos_term_rows() {
    local r="${LINES:-}"
    [[ "$r" =~ ^[0-9]+$ ]] || r=$(tput lines 2>/dev/null)
    [[ "$r" =~ ^[0-9]+$ ]] || r=24
    printf '%s' "$r"
}

# Paints exactly _P_H lines starting at buffer line _P_TOP, reverse-videoing
# the selected entry. Lines are clipped to the terminal width: a wrapped line
# would occupy two screen rows and desync the repaint's cursor arithmetic.
_repos_paint() {
    local v li line pre post text c0 limit
    limit=$(( _TERM_COLS - 4 ))
    [ "$limit" -lt 20 ] && limit=20
    for ((v = 0; v < _P_H; v++)); do
        li=$(( _P_TOP + v ))
        if [ "$li" -lt "${#_LINES[@]}" ]; then line="${_LINES[li]}"; else line=""; fi
        if [ "$_P_SEL" -ge 0 ] && [ "${_PICK_LINE[$_P_SEL]}" = "$li" ]; then
            c0=${_PICK_C0[$_P_SEL]}
            text="${_PICK_TEXT[$_P_SEL]}"
            pre="${line:0:c0 - 1}"
            post="${line:c0 - 1 + ${#text}}"
            text="${text:0:limit}"
            post="${post:0:limit - ${#pre} - ${#text}}"
            printf '%s\e[7m%s\e[0m%s\e[K\n' "$pre" "$text" "$post"
        else
            printf '%s\e[K\n' "${line:0:limit}"
        fi
    done
}

# Keeps the selected entry inside the visible window.
_repos_pick_scroll() {
    local li="${_PICK_LINE[$_P_SEL]}" maxtop
    [ "$li" -lt "$_P_TOP" ] && _P_TOP=$li
    [ "$li" -ge $(( _P_TOP + _P_H )) ] && _P_TOP=$(( li - _P_H + 1 ))
    maxtop=$(( ${#_LINES[@]} - _P_H ))
    [ "$maxtop" -lt 0 ] && maxtop=0
    [ "$_P_TOP" -gt "$maxtop" ] && _P_TOP=$maxtop
    [ "$_P_TOP" -lt 0 ] && _P_TOP=0
}

# Moves the highlight one display row up (-1) or down (+1), landing on the
# entry nearest the current column. Works for both the one-per-line view and
# the compact grid without either needing special handling.
_repos_pick_vert() {
    local dir="$1" n="${#_PICK_PATHS[@]}"
    local curline="${_PICK_LINE[$_P_SEL]}" curcol="${_PICK_C0[$_P_SEL]}"
    local best=-1 bestline=-1 bestdist=999999 i r c d
    for ((i = 0; i < n; i++)); do
        r="${_PICK_LINE[i]}"
        if [ "$dir" -lt 0 ]; then
            [ "$r" -ge "$curline" ] && continue
            { [ "$bestline" -lt 0 ] || [ "$r" -gt "$bestline" ]; } && bestline=$r
        else
            [ "$r" -le "$curline" ] && continue
            { [ "$bestline" -lt 0 ] || [ "$r" -lt "$bestline" ]; } && bestline=$r
        fi
    done
    [ "$bestline" -lt 0 ] && return 1
    for ((i = 0; i < n; i++)); do
        [ "${_PICK_LINE[i]}" -eq "$bestline" ] || continue
        c="${_PICK_C0[i]}"
        if [ "$c" -gt "$curcol" ]; then d=$(( c - curcol )); else d=$(( curcol - c )); fi
        if [ "$d" -lt "$bestdist" ]; then bestdist=$d; best=$i; fi
    done
    [ "$best" -ge 0 ] && _P_SEL=$best
    return 0
}

# Reads one byte into $c, preferring the replay buffer over the terminal.
# $1 is the terminal read timeout. Relies on bash dynamic scoping to assign
# the caller's $c. Both the key loop and the escape-sequence reader must come
# through here, or replayed bytes are visible to only one of them.
_pick_getch() {
    if [ -n "$_PICK_PENDING" ]; then
        c="${_PICK_PENDING:0:1}"
        _PICK_PENDING="${_PICK_PENDING:1}"
        return 0
    fi
    # -d '' sets the delimiter to NUL so Enter is returned as a real \n or \r.
    # With the default delimiter, read consumes the newline and yields an empty
    # string -- indistinguishable from a read cut short by a signal, which made
    # Ctrl-C occasionally register as Enter and cd somewhere.
    IFS= read -rsn1 -d '' -t "$1" c
}

# Consumes the tables filled in by the renderer.
# Sets _PICK_ACTION (cd|pin|cancel) and _PICK_INDEX.
_repos_pick() {
    local n="${#_PICK_PATHS[@]}"
    _PICK_ACTION="cancel"; _PICK_INDEX=-1
    [ "$n" -eq 0 ] && return 1

    if ! _repos_tui_capable; then
        local l
        for l in "${_LINES[@]}"; do printf '%s\n' "$l"; done
        printf '🔢 Enter a number: '
        local choice; read -r choice
        if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$n" ]; then
            _PICK_ACTION="cd"; _PICK_INDEX=$(( choice - 1 ))
            return 0
        fi
        return 1
    fi

    local total="${#_LINES[@]}" rows
    rows=$(_repos_term_rows)
    _P_SEL=0; _P_TOP=0

    # Toggling a pin re-renders with the entry lifted into the pinned block, so
    # every index shifts. Without this the cursor would snap back to index 0 --
    # which is the entry just pinned -- and a second press would unpin it,
    # making it impossible to hold more than one pin.
    if [ -n "$_PICK_WANT" ]; then
        local want_key wi
        _repos_key "$_PICK_WANT"; want_key="$_KEY"
        for ((wi = 0; wi < n; wi++)); do
            _repos_key "${_PICK_PATHS[wi]}"
            [ "$_KEY" = "$want_key" ] && { _P_SEL=$wi; break; }
        done
        _PICK_WANT=""
    fi

    _P_H=$(( rows - 3 ))
    [ "$_P_H" -gt "$total" ] && _P_H=$total
    [ "$_P_H" -lt 1 ] && _P_H=1

    local prompt buf=""
    prompt='↑↓←→ move · Enter open · p pin · q/Ctrl-C quit  '

    # Already in cbreak mode means we are looping back in after a pin toggle.
    # Re-capturing here would save cbreak as the "original" settings and the
    # final restore would hand back a broken terminal.
    if [ "$_PICK_RAW_ON" != "1" ]; then
        # If the current settings can't be captured there is no way to restore
        # them afterwards, so stay in cooked mode rather than wedge the terminal.
        if ! _PICK_STTY=$(stty -g 2>/dev/null) || [ -z "$_PICK_STTY" ]; then
            _PICK_STTY=""
            local l
            for l in "${_LINES[@]}"; do printf '%s\n' "$l"; done
            printf '🔢 Enter a number: '
            local choice; read -r choice
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "$n" ]; then
                _PICK_ACTION="cd"; _PICK_INDEX=$(( choice - 1 ))
                return 0
            fi
            return 1
        fi

        # -icanon -echo rather than raw: raw also clears ONLCR, which turns
        # every newline in the repaint into a staircase.
        #
        # isig is deliberately left ENABLED. Suppressing it would make Ctrl-C a
        # plain byte, which is tidier, but then a picker that wedges before its
        # cleanup runs leaves a terminal that cannot be interrupted at all.
        # With isig on, Ctrl-C always raises SIGINT, bash always unwinds, and
        # the trap always restores the terminal. susp is undefined so Ctrl-Z
        # cannot suspend the picker mid-repaint and strand it in -echo.
        stty -icanon -echo min 1 time 0 2>/dev/null
        stty susp undef 2>/dev/null
        _PICK_RAW_ON=1
    fi
    _PICK_ABORT=0
    trap '_PICK_ABORT=1; _repos_pick_cleanup' INT TERM HUP
    trap '' TSTP

    _PICK_MOUSE_ON=1
    printf '\e[?1000h\e[?1006h' > /dev/tty

    _repos_pick_scroll
    _repos_paint
    printf '%s\e[K' "$prompt"

    # The block is a fixed height and never scrolls again, so one cursor query
    # is enough to map a click row back to a buffer line.
    local block_row
    if _repos_cursor_row; then
        block_row=$(( _CURSOR_ROW - _P_H ))
    else
        block_row=-9999
    fi

    local c seq ch btn mx my ev i hit li v redraw rc
    # Poll rather than block: bash will not interrupt a blocking read to run a
    # trap, so a SIGINT-delivered Ctrl-C would otherwise sit unnoticed until the
    # next keystroke — and swallow it.
    while true; do
        _pick_getch 0.2; rc=$?
        [ "$_PICK_ABORT" = "1" ] && break
        [ "$rc" -gt 128 ] && continue
        [ "$rc" -eq 0 ] || break
        redraw=0
        case "$c" in
            $'\e')
                seq=""
                while _pick_getch 0.05; do
                    ch="$c"
                    seq+="$ch"
                    [[ "$ch" == [A-Za-z~] ]] && break
                    [ "${#seq}" -ge 32 ] && break
                done
                [ -z "$seq" ] && break
                case "$seq" in
                    '[A'|'OA') _repos_pick_vert -1; buf=""; redraw=1 ;;
                    '[B'|'OB') _repos_pick_vert 1;  buf=""; redraw=1 ;;
                    '[C'|'OC') [ "$_P_SEL" -lt $(( n - 1 )) ] && _P_SEL=$(( _P_SEL + 1 )); buf=""; redraw=1 ;;
                    '[D'|'OD') [ "$_P_SEL" -gt 0 ] && _P_SEL=$(( _P_SEL - 1 )); buf=""; redraw=1 ;;
                    '[H'|'OH'|'[1~') _P_SEL=0; buf=""; redraw=1 ;;
                    '[F'|'OF'|'[4~') _P_SEL=$(( n - 1 )); buf=""; redraw=1 ;;
                    '[5~') for ((i = 0; i < _P_H / 2; i++)); do _repos_pick_vert -1 || break; done; buf=""; redraw=1 ;;
                    '[6~') for ((i = 0; i < _P_H / 2; i++)); do _repos_pick_vert 1 || break; done; buf=""; redraw=1 ;;
                    *)
                        # SGR mouse report; only right-click (button 2) acts.
                        if [[ "$seq" =~ ^\[\<([0-9]+)\;([0-9]+)\;([0-9]+)([Mm])$ ]]; then
                            btn="${BASH_REMATCH[1]}"; mx="${BASH_REMATCH[2]}"
                            my="${BASH_REMATCH[3]}"; ev="${BASH_REMATCH[4]}"
                            [ "$ev" = "m" ] || continue
                            [ $(( btn & 3 )) -eq 2 ] || continue
                            v=$(( my - block_row ))
                            [ "$v" -lt 0 ] || [ "$v" -ge "$_P_H" ] && continue
                            li=$(( _P_TOP + v ))
                            hit=-1
                            for ((i = 0; i < n; i++)); do
                                [ "${_PICK_LINE[i]}" -eq "$li" ] || continue
                                if [ "$mx" -ge "${_PICK_C0[i]}" ] \
                                    && [ "$mx" -lt $(( _PICK_C0[i] + ${#_PICK_TEXT[i]} )) ]; then
                                    hit=$i; break
                                fi
                            done
                            [ "$hit" -lt 0 ] && continue
                            _PICK_INDEX=$hit; _PICK_ACTION="pin"
                            break
                        fi
                        ;;
                esac
                ;;
            [0-9])
                buf+="$c"
                if [ "$buf" -ge 1 ] 2>/dev/null && [ "$buf" -le "$n" ]; then
                    _P_SEL=$(( buf - 1 ))
                fi
                redraw=1 ;;
            $'\177'|$'\b')
                buf="${buf%?}"
                if [ -n "$buf" ] && [ "$buf" -ge 1 ] 2>/dev/null && [ "$buf" -le "$n" ]; then
                    _P_SEL=$(( buf - 1 ))
                fi
                redraw=1 ;;
            p|P)
                _PICK_INDEX=$_P_SEL; _PICK_ACTION="pin"; break ;;
            $'\r'|$'\n')
                _PICK_INDEX=$_P_SEL; _PICK_ACTION="cd"; break ;;
            $'\003'|q|Q)
                break ;;
        esac

        if [ "$redraw" -eq 1 ]; then
            _repos_pick_scroll
            printf '\r\e[%dA' "$_P_H"
            _repos_paint
            printf '%s%s\e[K' "$prompt" "$buf"
        fi
    done

    trap - INT TERM HUP TSTP
    # A signal-delivered Ctrl-C may have landed mid-action; cancel either way.
    [ "$_PICK_ABORT" = "1" ] && { _PICK_ACTION="cancel"; _PICK_INDEX=-1; }
    _PICK_ABORT=0

    # A pin toggle loops straight back in to re-render. Dropping to cooked mode
    # in between would echo any keys pressed during the rebuild and line-buffer
    # them out of reach, losing rapid presses; stay in cbreak instead.
    if [ "$_PICK_ACTION" = "pin" ]; then
        printf '\n'
        return 0
    fi

    _repos_pick_cleanup
    printf '\n'
    [ "$_PICK_ACTION" = "cancel" ] && return 1
    return 0
}

# ---------------------------------------------------------------------------
# Renderer. Lines are buffered rather than printed so the picker can repaint
# them; each entry records the line it sits on and its span within that line.
# ---------------------------------------------------------------------------

_rl_reset() { _LINES=(); _PICK_PATHS=(); _PICK_LINE=(); _PICK_C0=(); _PICK_TEXT=(); }
_rl_line()  { _LINES+=("$1"); }
_rl_blank() { _LINES+=(""); }

_rl_item() {
    _PICK_LINE[$1]=${#_LINES[@]}
    _PICK_C0[$1]=1
    _PICK_TEXT[$1]="$2"
    _LINES+=("$2")
}

# Lays _G_LBL/_G_IDX out in columns. Cells are ASCII-only: emoji are double
# width, which would desync both the padding and the highlight spans.
_repos_grid() {
    local indent="$1" maxw=0 i n cols rows r c idx cell line pad
    n=${#_G_IDX[@]}
    [ "$n" -eq 0 ] && return 0
    for ((i = 0; i < n; i++)); do
        [ "${#_G_LBL[i]}" -gt "$maxw" ] && maxw=${#_G_LBL[i]}
    done
    local w=$(( maxw + 2 ))
    cols=$(( (_TERM_COLS - indent) / w ))
    [ "$cols" -lt 1 ] && cols=1
    rows=$(( (n + cols - 1) / cols ))
    printf -v pad "%${indent}s" ""
    for ((r = 0; r < rows; r++)); do
        line="$pad"
        for ((c = 0; c < cols; c++)); do
            i=$(( r * cols + c ))
            [ "$i" -ge "$n" ] && break
            idx=${_G_IDX[i]}
            printf -v cell "%-${w}s" "${_G_LBL[i]}"
            _PICK_LINE[$idx]=${#_LINES[@]}
            _PICK_C0[$idx]=$(( ${#line} + 1 ))
            _PICK_TEXT[$idx]="$cell"
            line+="$cell"
        done
        _LINES+=("$line")
    done
}

repos() {
    # -h keeps its original "go to ~/repos" meaning; --help prints usage.
    if [[ "$1" == "-h" ]]; then
        cd ~/repos
        return 0
    fi

    local compact=0 pinned_only=0 search=""
    [ "$REPOS_COMPACT" = "1" ] && compact=1

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -c|--compact) compact=1 ;;
            -f|--full)    compact=0 ;;
            -p|--pinned)  pinned_only=1 ;;
            --help)
                echo "Usage: repos [-c|--compact] [-f|--full] [-p|--pinned] [search]"
                echo ""
                echo "  -c, --compact  Group by location and show names only"
                echo "  -f, --full     Force the full path view"
                echo "  -p, --pinned   Pinned entries only (same as rpin)"
                echo "  -h             cd to ~/repos"
                echo ""
                echo "Pinned entries are listed first. Use the arrow keys to move,"
                echo "Enter to cd, or type an entry's number. 'p' or a right-click"
                echo "toggles that entry's pin. q, Escape or Ctrl-C cancels."
                echo ""
                echo "Env: REPOS_COMPACT=1 makes compact the default,"
                echo "     REPOS_TUI=0 falls back to a plain numbered prompt."
                return 0 ;;
            *) [ -z "$search" ] && search="$1" ;;
        esac
        shift
    done

    _repos_browse "$compact" "$pinned_only" "$search"
    local rc=$?
    # No-op if the picker already tidied up; catches any abnormal exit from it.
    _repos_pick_cleanup
    return $rc
}

_repos_browse() {
    local compact="$1" pinned_only="$2" search="$3"

    if ! _repos_jq >/dev/null; then
        echo "❌ jq is not available. Install jq or run jq_install."
        return 1
    fi

    _TERM_COLS=$(_repos_term_cols)
    _PICK_WANT=""
    # Carried across pin re-renders inside the loop below, but never into a
    # fresh invocation, where it would replay stale keystrokes.
    _PICK_PENDING=""

    # repos.json and worktrees.json cannot change while the picker is open, so
    # read them once. Only pins.json is re-read per loop. This keeps a pin
    # re-render cheap: a slow rebuild is a window in which keystrokes pile up.
    local all_repos=() all_wts=() p
    mapfile -t all_repos < <(_repos_read_json "$BASH_FUNCTIONS_DIR/repos.json")
    mapfile -t all_wts < <(_repos_read_json "$BASH_FUNCTIONS_DIR/worktrees.json")

    local -A kind_of=()
    for p in "${all_repos[@]}"; do _repos_key "$p"; kind_of["$_KEY"]="repo"; done
    for p in "${all_wts[@]}"; do _repos_key "$p"; kind_of["$_KEY"]="worktree"; done

    while true; do
        local pins=()
        mapfile -t pins < <(_pins_read)

        local -A pinned_set=()
        for p in "${pins[@]}"; do _repos_key "$p"; pinned_set["$_KEY"]=1; done

        # Pinned entries are lifted out of their normal section rather than
        # repeated, so each path owns exactly one number.
        local sec_pin=() sec_repo=() sec_wt=()
        for p in "${pins[@]}"; do
            _repos_match "$p" "$search" && sec_pin+=("$p")
        done
        if [ "$pinned_only" -ne 1 ]; then
            for p in "${all_repos[@]}"; do
                _repos_key "$p"; [ -n "${pinned_set[$_KEY]}" ] && continue
                _repos_match "$p" "$search" && sec_repo+=("$p")
            done
            for p in "${all_wts[@]}"; do
                _repos_key "$p"; [ -n "${pinned_set[$_KEY]}" ] && continue
                _repos_match "$p" "$search" && sec_wt+=("$p")
            done
        fi

        if [ "${#sec_pin[@]}" -eq 0 ] && [ "${#sec_repo[@]}" -eq 0 ] && [ "${#sec_wt[@]}" -eq 0 ]; then
            if [ -n "$search" ]; then
                echo "🔍 No matches for \"$search\"."
            elif [ "$pinned_only" -eq 1 ]; then
                echo "📭 No pins yet. Pin the current directory with: rpin_toggle"
            else
                echo "📭 No repos or worktrees found."
            fi
            return 1
        fi

        _rl_reset
        local idx=0 lbl marker missing

        if [ "${#sec_pin[@]}" -gt 0 ]; then
            _rl_line "📌 Pinned"
            if [ "$compact" -eq 1 ]; then
                # Basenames alone are ambiguous across pins (several "main"
                # worktrees), so duplicates get their parent prefixed.
                local -A base_count=()
                local base parent
                for p in "${sec_pin[@]}"; do
                    _repos_norm "$p"; base="${_NORM##*/}"
                    base_count["${base,,}"]=$(( ${base_count["${base,,}"]:-0} + 1 ))
                done
                _G_IDX=(); _G_LBL=()
                for p in "${sec_pin[@]}"; do
                    _repos_norm "$p"; base="${_NORM##*/}"; parent="${_NORM%/*}"
                    [ "${base_count["${base,,}"]}" -gt 1 ] && base="${parent##*/}/$base"
                    [ -d "$_NORM" ] || base="$base!"
                    _PICK_PATHS+=("$p")
                    printf -v lbl '[%d] %s' "$(( idx + 1 ))" "$base"
                    _G_IDX+=("$idx"); _G_LBL+=("$lbl")
                    idx=$(( idx + 1 ))
                done
                _repos_grid 2
            else
                for p in "${sec_pin[@]}"; do
                    _repos_key "$p"
                    case "${kind_of[$_KEY]}" in
                        repo)     marker="📁" ;;
                        worktree) marker="🌳" ;;
                        *)        marker="📎" ;;
                    esac
                    _repos_norm "$p"
                    missing=""; [ -d "$_NORM" ] || missing="  ⚠️ missing"
                    _repos_label "$p"
                    _PICK_PATHS+=("$p")
                    printf -v lbl '  [%d] %s %s%s' "$(( idx + 1 ))" "$marker" "$_LABEL" "$missing"
                    _rl_item "$idx" "$lbl"
                    idx=$(( idx + 1 ))
                done
            fi
            _rl_blank
        fi

        if [ "$compact" -eq 1 ]; then
            local combined=("${sec_repo[@]}" "${sec_wt[@]}")
            if [ "${#combined[@]}" -gt 0 ]; then
                local -A groups=()
                for p in "${combined[@]}"; do
                    _repos_norm "$p"
                    groups["${_NORM%/*}"]+="$p"$'\n'
                done
                local gkey members=() all_wt_group base
                while IFS= read -r gkey; do
                    [ -z "$gkey" ] && continue
                    mapfile -t members < <(printf '%s' "${groups[$gkey]}")
                    all_wt_group=1
                    for p in "${members[@]}"; do
                        [ -z "$p" ] && continue
                        _repos_key "$p"
                        [ "${kind_of[$_KEY]}" = "worktree" ] || all_wt_group=0
                    done
                    _repos_label "$gkey"
                    [ "$all_wt_group" -eq 1 ] && _rl_line "$_LABEL  🌳" || _rl_line "$_LABEL"
                    _G_IDX=(); _G_LBL=()
                    for p in "${members[@]}"; do
                        [ -z "$p" ] && continue
                        _repos_norm "$p"; base="${_NORM##*/}"
                        [ -d "$_NORM" ] || base="$base!"
                        _PICK_PATHS+=("$p")
                        printf -v lbl '[%d] %s' "$(( idx + 1 ))" "$base"
                        _G_IDX+=("$idx"); _G_LBL+=("$lbl")
                        idx=$(( idx + 1 ))
                    done
                    _repos_grid 2
                    _rl_blank
                done < <(printf '%s\n' "${!groups[@]}" | sort)
            fi
        else
            if [ "${#sec_repo[@]}" -gt 0 ]; then
                _rl_line "📁 Repositories"
                for p in "${sec_repo[@]}"; do
                    _repos_norm "$p"
                    missing=""; [ -d "$_NORM" ] || missing="  ⚠️ missing"
                    _repos_label "$p"
                    _PICK_PATHS+=("$p")
                    printf -v lbl '  [%d] %s%s' "$(( idx + 1 ))" "$_LABEL" "$missing"
                    _rl_item "$idx" "$lbl"
                    idx=$(( idx + 1 ))
                done
                _rl_blank
            fi
            if [ "${#sec_wt[@]}" -gt 0 ]; then
                _rl_line "🌳 Worktrees"
                for p in "${sec_wt[@]}"; do
                    _repos_norm "$p"
                    missing=""; [ -d "$_NORM" ] || missing="  ⚠️ missing"
                    _repos_label "$p"
                    _PICK_PATHS+=("$p")
                    printf -v lbl '  [%d] %s%s' "$(( idx + 1 ))" "$_LABEL" "$missing"
                    _rl_item "$idx" "$lbl"
                    idx=$(( idx + 1 ))
                done
                _rl_blank
            fi
        fi

        # Auto-cd when a search narrows to exactly one hit.
        if [ -n "$search" ] && [ "${#_PICK_PATHS[@]}" -eq 1 ]; then
            _repos_norm "${_PICK_PATHS[0]}"
            echo "📂 Changing directory to: $_NORM"
            cd "$_NORM" || { echo "❌ Failed to change directory to: $_NORM"; return 1; }
            return 0
        fi

        _repos_pick || { echo "❌ Cancelled."; return 1; }

        # Capture the path immediately: _pins_has/_pins_add walk the pin list
        # with _repos_norm, which overwrites the shared $_NORM they return
        # through. Reading $_NORM after calling them yields the last pin
        # compared, not this entry.
        local selected="${_PICK_PATHS[$_PICK_INDEX]}"
        _repos_norm "$selected"
        local target="$_NORM"

        if [ "$_PICK_ACTION" = "pin" ]; then
            if _pins_has "$target"; then
                _pins_remove "$target"
                echo "📌 Unpinned: $target"
            else
                _pins_add "$target"
                echo "📌 Pinned: $target"
            fi
            # Keep the cursor on this entry once the list re-renders around it.
            _PICK_WANT="$target"
            continue
        fi

        echo "📂 Changing directory to: $target"
        cd "$target" || { echo "❌ Failed to change directory to: $target"; return 1; }
        return 0
    done
}

# ---------------------------------------------------------------------------
# Pin commands
# ---------------------------------------------------------------------------

rpin() {
    local compact=0 search=""
    [ "$REPOS_COMPACT" = "1" ] && compact=1

    while [ "$#" -gt 0 ]; do
        case "$1" in
            -c|--compact) compact=1 ;;
            -f|--full)    compact=0 ;;
            -l|--list)    ;;
            -d|--delete)
                shift
                _rpin_delete "$1"
                return $? ;;
            -m|--move)
                shift
                _rpin_move "$1" "$2"
                return $? ;;
            -C|--clear)
                local count=0
                count=$(_pins_read | wc -l)
                [ "$count" -eq 0 ] && { echo "📭 No pins to clear."; return 0; }
                read -r -p "⚠️  Clear all $count pins? (y/n): " confirm
                [[ "$confirm" == [yY] ]] || { echo "❌ Cancelled."; return 0; }
                _pins_write
                echo "✅ Cleared all pins."
                return 0 ;;
            --prune)
                _rpin_prune
                return $? ;;
            --help)
                echo "Usage: rpin [-c] [search]        List and navigate pins"
                echo "       rpin -d <n>               Unpin by number"
                echo "       rpin -m <from> <to>       Reorder a pin"
                echo "       rpin --prune              Drop pins whose path no longer exists"
                echo "       rpin -C                   Clear all pins"
                echo "       rpin_toggle [path]        Pin/unpin a path (default: cwd)"
                echo ""
                echo "A pin may be a repo, a worktree, or unattached (any other folder)."
                return 0 ;;
            *) [ -z "$search" ] && search="$1" ;;
        esac
        shift
    done

    _repos_browse "$compact" 1 "$search"
    local rc=$?
    _repos_pick_cleanup
    return $rc
}

_rpin_delete() {
    local n="$1" pins=()
    mapfile -t pins < <(_pins_read)
    if ! [[ "$n" =~ ^[0-9]+$ ]] || [ "$n" -lt 1 ] || [ "$n" -gt "${#pins[@]}" ]; then
        echo "❌ Invalid pin number: $n"
        return 1
    fi
    local target="${pins[$(( n - 1 ))]}"
    _pins_remove "$target"
    echo "📌 Unpinned: $target"
}

_rpin_move() {
    local from="$1" to="$2" pins=()
    mapfile -t pins < <(_pins_read)
    local count="${#pins[@]}"
    if ! [[ "$from" =~ ^[0-9]+$ ]] || [ "$from" -lt 1 ] || [ "$from" -gt "$count" ] \
        || ! [[ "$to" =~ ^[0-9]+$ ]] || [ "$to" -lt 1 ] || [ "$to" -gt "$count" ]; then
        echo "❌ Usage: rpin -m <from> <to>  (1-$count)"
        return 1
    fi
    local moved="${pins[$(( from - 1 ))]}" rest=() out=() i
    for ((i = 0; i < count; i++)); do
        [ "$i" -eq $(( from - 1 )) ] && continue
        rest+=("${pins[i]}")
    done
    for ((i = 0; i < ${#rest[@]}; i++)); do
        [ "$i" -eq $(( to - 1 )) ] && out+=("$moved")
        out+=("${rest[i]}")
    done
    [ "$to" -gt "${#rest[@]}" ] && out+=("$moved")
    _pins_write "${out[@]}"
    echo "📌 Moved pin $from to position $to: $moved"
}

_rpin_prune() {
    local p keep=() dropped=0
    while IFS= read -r p; do
        _repos_norm "$p"
        if [ -d "$_NORM" ]; then
            keep+=("$p")
        else
            echo "🗑️  Dropping missing pin: $p"
            dropped=$(( dropped + 1 ))
        fi
    done < <(_pins_read)
    if [ "$dropped" -eq 0 ]; then
        echo "✅ All pins resolve."
        return 0
    fi
    _pins_write "${keep[@]}"
    echo "✅ Pruned $dropped pin(s)."
}

rpin_toggle() {
    local arg="${1:-.}"

    # An existing path toggles directly; anything else is treated as a search
    # across repos, worktrees and current pins.
    if [ ! -e "$arg" ]; then
        local candidates=() p seen=""
        local -A dedup=()
        while IFS= read -r p; do
            _repos_key "$p"; [ -n "${dedup[$_KEY]}" ] && continue
            dedup["$_KEY"]=1
            _repos_match "$p" "$arg" && candidates+=("$p")
        done < <( { _pins_read; _repos_read_json "$BASH_FUNCTIONS_DIR/repos.json"; \
                    _repos_read_json "$BASH_FUNCTIONS_DIR/worktrees.json"; } )

        if [ "${#candidates[@]}" -eq 0 ]; then
            echo "❌ No path or match for: $arg"
            return 1
        elif [ "${#candidates[@]}" -eq 1 ]; then
            arg="${candidates[0]}"
        else
            _TERM_COLS=$(_repos_term_cols)
            _rl_reset
            _rl_line "📌 Toggle pin for:"
            local i lbl pinmark
            for ((i = 0; i < ${#candidates[@]}; i++)); do
                _repos_label "${candidates[i]}"
                pinmark=""; _pins_has "${candidates[i]}" && pinmark="  📌"
                _PICK_PATHS+=("${candidates[i]}")
                printf -v lbl '  [%d] %s%s' "$(( i + 1 ))" "$_LABEL" "$pinmark"
                _rl_item "$i" "$lbl"
            done
            _rl_blank
            _repos_pick || { echo "❌ Cancelled."; return 1; }
            arg="${_PICK_PATHS[$_PICK_INDEX]}"
        fi
    fi

    _repos_norm "$arg"
    local target="$_NORM"
    if [ -d "$target" ]; then
        # pwd -W matches the Windows form that jq.exe's argument conversion
        # produces for repos.json, so mount aliases like /tmp still match.
        target=$(cd "$target" 2>/dev/null && { pwd -W 2>/dev/null || pwd; })
        _repos_norm "$target"; target="$_NORM"
    fi

    if _pins_has "$target"; then
        _pins_remove "$target"
        echo "📌 Unpinned: $target"
    else
        _pins_add "$target"
        local kind
        kind=$(_pins_kind "$target")
        echo "📌 Pinned ($kind): $target"
    fi
}

reposcheck() {
    local json_file="$BASH_FUNCTIONS_DIR/repos.json"
    local worktrees_json="$BASH_FUNCTIONS_DIR/worktrees.json"
    local jq="$BASH_FUNCTIONS_DIR/jq"

    # Check repos from repos.json
    if [ -f "$json_file" ]; then
        mapfile -t repos < <("$jq" -r '.[]' "$json_file")
        
        if [ "${#repos[@]}" -gt 0 ]; then
            echo "📁 Repositories:"
            for repo in "${repos[@]}"; do
                repo=$(echo "$repo" | xargs)
                cd "$repo" 2>/dev/null || continue
                if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
                    echo "  ❌ Changes: $repo"
                else
                    echo "  ✅ Clean:   $repo"
                fi
            done
            echo ""
        fi
    fi

    # Check worktrees from worktrees.json
    if [ -f "$worktrees_json" ]; then
        mapfile -t worktrees < <("$jq" -r '.[]' "$worktrees_json")
        
        if [ "${#worktrees[@]}" -gt 0 ]; then
            echo "🌳 Worktrees:"
            for worktree in "${worktrees[@]}"; do
                worktree=$(echo "$worktree" | xargs)
                [ -d "$worktree" ] || continue
                cd "$worktree" 2>/dev/null || continue
                if [[ -n $(git status --porcelain 2>/dev/null) ]]; then
                    echo "  ❌ Changes: $worktree"
                else
                    echo "  ✅ Clean:   $worktree"
                fi
            done
        fi
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

reponew() {
    local name="$1"
    local is_wt=false
    
    # Parse arguments
    while [[ "$#" -gt 0 ]]; do
        case $1 in
            --wt|-w) is_wt=true ;;
            *) [ -z "$name" ] && name="$1" ;;
        esac
        shift
    done

    if [ -z "$name" ]; then
        echo "❌ Usage: reponew <repo-name> [--wt|-w]"
        return 1
    fi

    local repos_root="$HOME/repos"
    local worktrees_root="$HOME/worktrees"
    local final_repo_path

    if [ "$is_wt" = true ]; then
        # Worktree structure: ~/worktrees/repo-name/main
        final_repo_path="$worktrees_root/$name/main"
        echo "📂 Creating worktree project: $name"
    else
        # Normal structure: ~/repos/repo-name
        final_repo_path="$repos_root/$name"
        echo "📂 Creating new project: $name"
    fi

    # Create directories
    if [ ! -d "$final_repo_path" ]; then
        mkdir -p "$final_repo_path"
    fi
    
    # Change to directory
    cd "$final_repo_path" || { echo "❌ Failed to enter directory $final_repo_path"; return 1; }

    # Initialize Git
    if [ ! -d ".git" ]; then
        git init
        echo "✅ Git repository initialized."
    else
        echo "ℹ️ Git repository already initialized."
    fi

    # Add to repos.json
    repoadd .
}

alias repos_edit="$EDITOR $BASH_FUNCTIONS_DIR/repos.json"
alias worktrees_edit="$EDITOR $BASH_FUNCTIONS_DIR/worktrees.json"
alias pins_edit="$EDITOR $BASH_FUNCTIONS_DIR/pins.json"
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
alias wt='worktree'
alias wtc='worktree change'
alias wta='worktree add'
alias wtr='worktree remove'
alias wtl='worktree list'

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
        echo "  remove   - Remove worktree, delete directory, and delete local branch"
        echo "  change|c - Change directory to a worktree (interactive if no branch specified)"
        echo "  pull     - Pull changes for the current worktree's branch"
        echo "  list     - List all worktrees"
        echo ""
        echo "Flags:"
        echo "  --nested, -n  - Use nested directory structure (e.g., feat/branch instead of feat-branch)"
        echo ""
        echo "Aliases:"
        echo "  wt   - worktree"
        echo "  wta  - worktree add"
        echo "  wtc  - worktree change (interactive list)"
        echo "  wtr  - worktree remove"
        echo "  wtl  - worktree list"
        echo ""
        echo "Examples:"
        echo "  worktree add feat/new-feature           # Create new branch and worktree"
        echo "  worktree add --nested feat/new-feature  # Create with nested directory"
        echo "  worktree remove feat/new-feature        # Remove worktree, folder, and branch"
        echo "  worktree change feat/new-feature        # Switch to worktree"
        echo "  worktree change                         # Interactive selection"
        echo "  wtc                                     # Quick interactive selection"
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
            
            # Check if branch exists (locally or remotely)
            local branch_exists=false
            if git show-ref --verify --quiet "refs/heads/$branch_name"; then
                branch_exists=true
                echo "ℹ️  Branch '$branch_name' exists locally"
            elif git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
                branch_exists=true
                echo "ℹ️  Branch '$branch_name' exists on remote"
            fi
            
            echo "➕ Adding worktree for branch '$branch_name' at '$target_dir'..."
            
            # If branch doesn't exist, create it
            if [ "$branch_exists" = false ]; then
                echo "📝 Branch does not exist. Creating new branch '$branch_name'..."
                if git worktree add -b "$branch_name" "$target_dir"; then
                    echo "✅ Created new branch and worktree"
                else
                    echo "❌ Failed to create worktree"
                    return 1
                fi
            else
                # Branch exists, just add the worktree
                if git worktree add "$target_dir" "$branch_name"; then
                    echo "✅ Created worktree for existing branch"
                else
                    echo "❌ Failed to create worktree"
                    return 1
                fi
            fi
            
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
            
            read -p "⚠️ Remove worktree AND DELETE LOCAL branch '$branch_name'? (y/n): " confirm
            
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                # Get absolute path before removing
                local abs_path
                abs_path=$(cd "$target_dir" && pwd)
                
                # Try to remove with git worktree from repo root, use --force if it fails
                if ! git -C "$repo_root" worktree remove "$target_dir" 2>/dev/null; then
                    echo "⚠️  Worktree has modified files. Using --force..."
                    if ! git -C "$repo_root" worktree remove --force "$target_dir" 2>/dev/null; then
                        echo "⚠️  Git worktree remove failed. Running prune and force deleting directory..."
                        # Clean up git's worktree metadata
                        git -C "$repo_root" worktree prune 2>/dev/null
                    fi
                fi
                
                # Force delete the directory if it still exists
                if [ -d "$target_dir" ]; then
                    echo "🗑️  Force deleting directory: $target_dir"
                    rm -rf "$target_dir"
                    if [ -d "$target_dir" ]; then
                        echo "⚠️  Failed to delete directory. It may be locked by another process."
                        echo "💡 Tip: Close any programs using files in that directory, then run: rm -rf '$target_dir'"
                    else
                        echo "✅ Directory deleted."
                    fi
                else
                    echo "✅ Worktree removed."
                fi
                
                # Always remove from worktrees.json
                if [ -f "$worktrees_json" ]; then
                    tmp_file=$(mktemp)
                    "$jq_cmd" --arg path "$abs_path" 'map(select(. != $path))' "$worktrees_json" > "$tmp_file" && mv "$tmp_file" "$worktrees_json"
                    echo "✅ Removed from worktrees.json"
                fi
                _pins_remove "$abs_path" && echo "📌 Removed matching pin."
                
                # Delete local branch AFTER removing worktree (use git -C to run from repo context)
                echo "🗑️  Deleting local branch '$branch_name'..."
                if git -C "$repo_root" branch -D "$branch_name" 2>/dev/null; then
                    echo "✅ Deleted local branch '$branch_name'"
                else
                    echo "⚠️  Local branch '$branch_name' may not exist or already deleted"
                fi
            else
                echo "❌ Removal cancelled."
            fi
            ;;
        change|c)
            if [ -z "$branch_name" ]; then
                # No branch specified - show interactive list
                mapfile -t wt_list < <(git worktree list --porcelain | grep -E '^worktree|^branch' | paste -d ' ' - - | sed 's/worktree //; s/branch //')
                
                if [ "${#wt_list[@]}" -eq 0 ]; then
                    echo "❌ No worktrees found."
                    return 1
                fi
                
                echo "📁 Available Worktrees:"
                local wt_paths=()
                local wt_branches=()
                for i in "${!wt_list[@]}"; do
                    local wt_info="${wt_list[$i]}"
                    local wt_path=$(echo "$wt_info" | awk '{print $1}')
                    local wt_branch=$(echo "$wt_info" | awk '{print $2}' | sed 's|refs/heads/||')
                    wt_paths+=("$wt_path")
                    wt_branches+=("$wt_branch")
                    printf "[%d] %s (%s)\n" "$((i + 1))" "$wt_branch" "$wt_path"
                done
                
                echo -n "🔢 Enter a number to cd into that worktree: "
                read -r choice
                
                if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#wt_paths[@]}" ]; then
                    echo "❌ Invalid selection."
                    return 1
                fi
                
                local selected_path="${wt_paths[$((choice - 1))]}"
                echo "📂 Changing to worktree: $selected_path"
                cd "$selected_path" || echo "❌ Failed to change directory."
            else
                # Branch name specified - use existing logic
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

gits() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "❌ Error: Not inside a git repository."
        return 1
    fi

    local search_term="$1"

    local branches=()
    while IFS= read -r line; do
        branches+=("$line")
    done < <(git branch 2>/dev/null | sed 's/^[ *]*//' | grep -v 'HEAD ->' | sort -u)

    # Filter by search term if provided
    if [[ -n "$search_term" ]]; then
        local filtered_branches=()
        for branch in "${branches[@]}"; do
            [[ "${branch,,}" == *"${search_term,,}"* ]] && filtered_branches+=("$branch")
        done
        branches=("${filtered_branches[@]}")
    fi

    if [ "${#branches[@]}" -eq 0 ]; then
        [[ -n "$search_term" ]] && echo "🔍 No branches matching \"$search_term\"." || echo "📭 No branches found."
        return 1
    fi

    # Auto-switch if search returned exactly one result
    if [[ -n "$search_term" && "${#branches[@]}" -eq 1 ]]; then
        local selected="${branches[0]}"
        echo "🔀 Switching to branch: $selected"
        git checkout "$selected"
        return $?
    fi

    echo "🌿 Branches:"
    for i in "${!branches[@]}"; do
        printf "  [%d] %s\n" "$((i + 1))" "${branches[$i]}"
    done

    echo -n "🔢 Enter a number to switch to that branch: "
    read -r choice

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#branches[@]}" ]; then
        echo "❌ Invalid selection."
        return 1
    fi

    local selected="${branches[$((choice - 1))]}"
    echo "🔀 Switching to branch: $selected"
    git checkout "$selected"
}

gitm() {
    trap 'tput cnorm 2>/dev/null; echo ""; echo "Cancelled."; trap - INT; return 1' INT

    local filter="$1"

    echo ""
    echo "Git Branch Manager"
    echo "------------------"
    [ -n "$filter" ] && echo "Filter: \"$filter\"" && echo ""
    echo "[1] Switch branch"
    echo "[2] Bulk delete branches"
    echo "[3] Create branch"
    echo "[4] List local branches"
    echo ""
    read -rp "Choose an option: " option

    case "$option" in
        1)
            echo ""
            echo "Available branches:"
            echo ""

            local branches=()
            while IFS= read -r line; do
                if [ -n "$filter" ]; then
                    [[ "${line,,}" == *"${filter,,}"* ]] || continue
                fi
                branches+=("$line")
            done < <(git branch 2>/dev/null | sed 's/^[ *]*//' | grep -v 'HEAD ->' | sort -u)

            if [ "${#branches[@]}" -eq 0 ]; then
                if [ -n "$filter" ]; then
                    echo "No branches matching \"$filter\"."
                else
                    echo "No branches found."
                fi
                trap - INT
                return 1
            fi

            for i in "${!branches[@]}"; do
                printf "[%d] %s\n" "$((i + 1))" "${branches[$i]}"
            done

            echo ""
            read -rp "Enter branch number to switch to: " choice

            if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#branches[@]}" ]; then
                echo "Invalid selection."
                trap - INT
                return 1
            fi

            local selected="${branches[$((choice - 1))]}"
            local checkout_name
            checkout_name=$(echo "$selected" | sed 's|remotes/[^/]*/||')
            git checkout "$checkout_name"
            ;;

        2)
            local current_branch
            current_branch=$(git branch --show-current 2>/dev/null)

            local branches=()
            while IFS= read -r line; do
                [[ "$line" == "$current_branch" ]] && continue
                if [ -n "$filter" ]; then
                    [[ "${line,,}" == *"${filter,,}"* ]] || continue
                fi
                branches+=("$line")
            done < <(git branch 2>/dev/null | sed 's/^[ *]*//' | sort)

            if [ "${#branches[@]}" -eq 0 ]; then
                if [ -n "$filter" ]; then
                    echo "No branches matching \"$filter\" available to delete."
                else
                    echo "No branches available to delete (only current branch '$current_branch' exists)."
                fi
                trap - INT
                return 1
            fi

            local selected=()
            for i in "${!branches[@]}"; do
                selected[$i]=0
            done

            local cursor=0
            local total="${#branches[@]}"

            _gitm_render() {
                if [ "$1" != "first" ]; then
                    printf "\033[%dA" "$((total + 4))"
                fi

                echo ""
                echo "🗑️  Git Branch Bulk Delete (current: $current_branch)"
                echo "   ↑/↓ navigate | SPACE toggle | ENTER confirm | q quit"
                echo ""

                for i in "${!branches[@]}"; do
                    local marker="  "
                    local pointer="  "
                    if [ "${selected[$i]}" -eq 1 ]; then
                        marker="✅"
                    else
                        marker="  "
                    fi
                    if [ "$i" -eq "$cursor" ]; then
                        pointer="▸ "
                    else
                        pointer="  "
                    fi
                    printf "\033[K%s%s %s\n" "$pointer" "$marker" "${branches[$i]}"
                done
            }

            tput civis 2>/dev/null
            _gitm_render "first"

            while true; do
                IFS= read -rsn1 key

                case "$key" in
                    $'\x1b')
                        read -rsn2 -t 0.1 seq
                        case "$seq" in
                            '[A') ((cursor > 0)) && ((cursor--)) ;;
                            '[B') ((cursor < total - 1)) && ((cursor++)) ;;
                        esac
                        ;;
                    ' ')
                        if [ "${selected[$cursor]}" -eq 0 ]; then
                            selected[$cursor]=1
                        else
                            selected[$cursor]=0
                        fi
                        ;;
                    '')
                        break
                        ;;
                    'q'|'Q')
                        tput cnorm 2>/dev/null
                        echo ""
                        echo "Cancelled."
                        trap - INT
                        return 0
                        ;;
                esac

                _gitm_render
            done

            tput cnorm 2>/dev/null

            local to_delete=()
            for i in "${!branches[@]}"; do
                if [ "${selected[$i]}" -eq 1 ]; then
                    to_delete+=("${branches[$i]}")
                fi
            done

            if [ "${#to_delete[@]}" -eq 0 ]; then
                echo ""
                echo "No branches selected."
                trap - INT
                return 0
            fi

            echo ""
            echo "⚠️  Branches to delete:"
            for b in "${to_delete[@]}"; do
                echo "   - $b"
            done
            echo ""
            read -rp "Delete these ${#to_delete[@]} branch(es)? (y/n): " confirm

            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                for b in "${to_delete[@]}"; do
                    if git branch -D "$b" 2>/dev/null; then
                        echo "✅ Deleted: $b"
                    else
                        echo "❌ Failed to delete: $b"
                    fi
                done
            else
                echo "Cancelled."
            fi
            ;;

        3)
            echo ""
            read -rp "Enter new branch name: " new_branch

            if [ -z "$new_branch" ]; then
                echo "❌ No branch name provided."
                trap - INT
                return 1
            fi

            if git checkout -b "$new_branch"; then
                echo "✅ Created and switched to branch '$new_branch'"
            else
                echo "❌ Failed to create branch '$new_branch'"
            fi
            ;;

        4)
            echo ""
            echo "Local branches:"
            echo ""
            if [ -n "$filter" ]; then
                git branch | sed 's/^[ *]*//' | sort | grep -i -- "$filter" | nl -w2 -s') '
            else
                git branch | sed 's/^[ *]*//' | sort | nl -w2 -s') '
            fi
            ;;

        *)
            echo "Invalid option."
            trap - INT
            return 1
            ;;
    esac
    trap - INT
}