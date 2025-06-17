# Find files matching a pattern (case-insensitive)
findfiles() {
    if [ -z "$1" ]; then
        echo "Usage: findfiles <pattern> [--root|-r] [custom_dir]"
        return 1
    fi

    local pattern="$1"
    shift

    local start_dir="$HOME"  # Default to user's home
    if [ "$1" == "--root" ] || [ "$1" == "-r" ]; then
        start_dir="/"
        shift
    elif [ -n "$1" ]; then
        start_dir="$1"
        shift
    fi

    find "$start_dir" -type f -iname "$pattern"
}

# Find directories matching a pattern (case-insensitive)
# findfolders "test-folder" --root
findfolders() {
    if [ -z "$1" ]; then
        echo "Usage: findfolders <pattern> [--root|-r] [custom_dir]"
        return 1
    fi

    local pattern="$1"
    shift

    local start_dir="$HOME"
    if [ "$1" == "--root" ] || [ "$1" == "-r" ]; then
        start_dir="/"
        shift
    elif [ -n "$1" ]; then
        start_dir="$1"
        shift
    fi

    find "$start_dir" -type d -iname "$pattern" 2>/dev/null
}