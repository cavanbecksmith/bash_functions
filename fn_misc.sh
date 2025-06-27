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