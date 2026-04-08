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


generate_signature() {
    local json_payload="$1"
    local secret="$2"
    echo -n "$json_payload" | openssl dgst -sha256 -hmac "$secret" -binary | xxd -p -c 256
}

emojipick() {
    local JSON="$BASH_FUNCTIONS_DIR/.emoji-data-by-group.json"


    # Download once
    if [[ ! -f "$JSON" ]]; then
        echo "Downloading emoji data..."
        curl -sSL "https://unpkg.com/unicode-emoji-json@0.8.0/data-by-group.json" -o "$JSON"
    fi

    if [[ "$1" == "-a" ]]; then
        # Show all emojis grouped by category
        awk '
            /"group":/ {
                g=$0
                sub(/.*"group": *"/, "", g)
                sub(/".*/, "", g)
                print "\n🔹 " g ":"
            }
            /"emoji":/ {
                e=$0
                sub(/.*"emoji": *"/, "", e)
                sub(/".*/, "", e)
                print e
            }
        ' "$JSON"

    elif [[ "$1" == "-c" && -n "$2" ]]; then
        # Show emojis from specific category
        awk -v cat="$2" '
            $0 ~ "\"group\": \"" cat "\"" { show=1; next }
            show && /"emoji":/ {
                e=$0
                sub(/.*"emoji": *"/, "", e)
                sub(/".*/, "", e)
                print e
            }
            show && /\]/ { show=0 }
        ' "$JSON"

    elif [[ -n "$1" ]]; then
        # Search emoji by keyword
        awk -v kw="$1" '
            BEGIN { RS="{"; FS="\n" }
            {
                emoji=""; name=""
                for (i=1; i<=NF; i++) {
                    if ($i ~ /"emoji":/) {
                        e=$i
                        sub(/.*"emoji": *"/, "", e)
                        sub(/".*/, "", e)
                        emoji = e
                    }
                    if ($i ~ /"name":/) {
                        n=$i
                        sub(/.*"name": *"/, "", n)
                        sub(/".*/, "", n)
                        name = n
                    }
                }
                if (tolower(name) ~ tolower(kw) && emoji != "") {
                    print emoji, name
                }
            }
        ' "$JSON"

    else
        echo "Usage:"
        echo "  emojipick <keyword>         # Search emoji by keyword"
        echo "  emojipick -c <category>     # Show emojis in a category"
        echo "  emojipick -a                # List all emojis"
        echo ""
        echo "Available categories:"
        grep '"group":' "$JSON" | sed -E 's/.*"group": ?"([^"]+)".*/\1/' | sort | uniq
    fi
}

lsb() {
    local fn_dir="$BASH_FUNCTION_DIR"
    
    if [ -z "$fn_dir" ]; then
        echo "❌ BASH_FUNCTION_DIR not set"
        return 1
    fi

    echo "Bash Functions Library"
    echo "======================"
    echo

    # Loop through all fn_*.sh files
    for file in "$fn_dir"/fn_*.sh; do
        if [ -f "$file" ]; then
            local filename=$(basename "$file" .sh)
            
            # Extract function names (matches both "function name()" and "name()")
            local functions=$(grep -E '^\s*(function\s+)?[a-zA-Z_][a-zA-Z0-9_]*\s*\(\)' "$file" | \
                             sed -E 's/^\s*(function\s+)?([a-zA-Z_][a-zA-Z0-9_]*)\s*\(\).*/\2/' | \
                             sort)
            
            if [ -n "$functions" ]; then
                local len=${#filename}
                local underline=$(printf '%*s' "$len" | tr ' ' '-')
                echo "$filename"
                echo "$underline"
                echo "$functions"
                echo "---"
                echo
            fi
        fi
    done
    
    echo "========================="
    echo "💡 Run 'type <function_name>' to see definition"
}

# Convert RGB to Hex
# Usage: rgb2hex 255 128 0
rgb2hex() {
    if [[ $# -ne 3 ]]; then
        echo "Usage: rgb2hex R G B"
        echo "Example: rgb2hex 255 128 0"
        return 1
    fi
    
    local r=$1
    local g=$2
    local b=$3
    
    # Validate RGB values are numbers between 0-255
    if ! [[ "$r" =~ ^[0-9]+$ ]] || ! [[ "$g" =~ ^[0-9]+$ ]] || ! [[ "$b" =~ ^[0-9]+$ ]]; then
        echo "Error: RGB values must be numbers"
        return 1
    fi
    
    if [[ $r -lt 0 || $r -gt 255 || $g -lt 0 || $g -gt 255 || $b -lt 0 || $b -gt 255 ]]; then
        echo "Error: RGB values must be between 0 and 255"
        return 1
    fi
    
    # Convert to hex
    printf "#%02X%02X%02X\n" "$r" "$g" "$b"
}

# Convert Hex to RGB
# Usage: hex2rgb "#FF8000" or hex2rgb FF8000
hex2rgb() {
    if [[ $# -ne 1 ]]; then
        echo "Usage: hex2rgb <hex_color>"
        echo "Example: hex2rgb \"#FF8000\" or hex2rgb FF8000"
        return 1
    fi
    
    local hex="$1"
    
    # Remove # if present
    hex="${hex#\#}"
    
    # Validate hex format
    if ! [[ "$hex" =~ ^[0-9A-Fa-f]{6}$ ]]; then
        echo "Error: Invalid hex color format. Use 6 hex digits (e.g., FF8000 or #FF8000)"
        return 1
    fi
    
    # Convert to uppercase for consistency
    hex="${hex^^}"
    
    # Extract RGB values
    local r=$((16#${hex:0:2}))
    local g=$((16#${hex:2:2}))
    local b=$((16#${hex:4:2}))
    
    echo "rgb($r, $g, $b)"
}

# Convert RGB to Hex or Hex to RGB (auto-detect)
# Usage: color_convert 255 128 0 or color_convert "#FF8000"
color_convert() {
    if [[ $# -eq 1 ]]; then
        # Assume hex to RGB
        hex2rgb "$1"
    elif [[ $# -eq 3 ]]; then
        # Assume RGB to hex
        rgb2hex "$1" "$2" "$3"
    else
        echo "Usage:"
        echo "  color_convert R G B          # Convert RGB to hex"
        echo "  color_convert <hex_color>    # Convert hex to RGB"
        echo ""
        echo "Examples:"
        echo "  color_convert 255 128 0"
        echo "  color_convert \"#FF8000\""
        return 1
    fi
}