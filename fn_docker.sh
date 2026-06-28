
# =================== CONTAINER MANAGER

_dockm_containers() {
    local engine="$1"

    echo ""
    echo "Fetching container stats..."

    declare -A _cpu _mem
    while IFS=$'\t' read -r id cpu mem; do
        _cpu["$id"]="$cpu"
        _mem["$id"]="$mem"
    done < <("$engine" stats --no-stream --format $'{{.ID}}\t{{.CPUPerc}}\t{{.MemUsage}}' 2>/dev/null)

    local ids=() names=() images=() statuses=() ports=()
    while IFS=$'\t' read -r id name image status port; do
        ids+=("$id")
        names+=("$name")
        images+=("$image")
        statuses+=("$status")
        ports+=("$port")
    done < <("$engine" ps --format $'{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}' 2>/dev/null)

    if [ "${#ids[@]}" -eq 0 ]; then
        echo "No running containers found."
        return 0
    fi

    echo ""
    printf "%-4s %-22s %-28s %-22s %-8s %-20s %s\n" "#" "NAME" "IMAGE" "STATUS" "CPU%" "MEM" "PORTS"
    printf "%-4s %-22s %-28s %-22s %-8s %-20s %s\n" "---" "----" "-----" "------" "----" "---" "-----"

    for i in "${!ids[@]}"; do
        local id="${ids[$i]}"
        printf "%-4s %-22s %-28s %-22s %-8s %-20s %s\n" \
            "$((i+1))" \
            "${names[$i]:0:22}" \
            "${images[$i]:0:28}" \
            "${statuses[$i]:0:22}" \
            "${_cpu[$id]:-n/a}" \
            "${_mem[$id]:0:20}" \
            "${ports[$i]}"
    done

    echo ""
    read -rp "Enter container number (or 0 to go back): " choice

    if [[ "$choice" == "0" || -z "$choice" ]]; then
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#ids[@]}" ]; then
        echo "❌ Invalid selection."
        return 1
    fi

    local idx=$((choice - 1))
    local selected_id="${ids[$idx]}"
    local selected_name="${names[$idx]}"

    echo ""
    echo "┌─ Container: $selected_name"
    echo "│  ID:      $selected_id"
    echo "│  Image:   ${images[$idx]}"
    echo "│  Status:  ${statuses[$idx]}"
    echo "│  CPU:     ${_cpu[$selected_id]:-n/a}"
    echo "│  Memory:  ${_mem[$selected_id]:-n/a}"
    echo "└─ Ports:   ${ports[$idx]:-none}"
    echo ""
    echo "[1] Stop"
    echo "[2] Restart"
    echo "[3] Remove"
    echo "[0] Back"
    echo ""
    read -rp "Choose action: " action

    case "$action" in
        1)
            echo "Stopping $selected_name..."
            "$engine" stop "$selected_id" && echo "✅ Stopped." || echo "❌ Failed."
            ;;
        2)
            echo "Restarting $selected_name..."
            "$engine" restart "$selected_id" && echo "✅ Restarted." || echo "❌ Failed."
            ;;
        3)
            echo ""
            read -rp "⚠️  Remove container '$selected_name'? This cannot be undone. (y/n): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                "$engine" rm -f "$selected_id" && echo "✅ Removed." || echo "❌ Failed."
            else
                echo "Cancelled."
            fi
            ;;
        0|"") return 0 ;;
        *) echo "❌ Invalid action." ;;
    esac
}

_dockm_networks() {
    local engine="$1"

    local net_ids=() net_names=() net_drivers=() net_scopes=()
    while IFS=$'\t' read -r id name driver scope; do
        net_ids+=("$id")
        net_names+=("$name")
        net_drivers+=("$driver")
        net_scopes+=("$scope")
    done < <("$engine" network ls --format $'{{.ID}}\t{{.Name}}\t{{.Driver}}\t{{.Scope}}' 2>/dev/null)

    if [ "${#net_ids[@]}" -eq 0 ]; then
        echo "No networks found."
        return 0
    fi

    echo ""
    printf "%-4s %-28s %-12s %-10s %s\n" "#" "NAME" "DRIVER" "SCOPE" "ID"
    printf "%-4s %-28s %-12s %-10s %s\n" "---" "----" "------" "-----" "--"

    for i in "${!net_ids[@]}"; do
        printf "%-4s %-28s %-12s %-10s %s\n" \
            "$((i+1))" \
            "${net_names[$i]:0:28}" \
            "${net_drivers[$i]}" \
            "${net_scopes[$i]}" \
            "${net_ids[$i]}"
    done

    echo ""
    read -rp "Enter network number to inspect (or 0 to go back): " choice

    if [[ "$choice" == "0" || -z "$choice" ]]; then
        return 0
    fi

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#net_ids[@]}" ]; then
        echo "❌ Invalid selection."
        return 1
    fi

    local idx=$((choice - 1))
    echo ""
    echo "Network: ${net_names[$idx]}"
    echo "──────────────────────────"
    "$engine" network inspect "${net_ids[$idx]}" 2>/dev/null
}

dockm() {
    trap 'echo ""; echo "Cancelled."; trap - INT; return 1' INT

    local engine="${CONTAINER_ENGINE:-docker}"

    while true; do
        echo ""
        echo "Container Manager  [$engine]"
        echo "─────────────────────────────"
        echo "[1] Manage Containers"
        echo "[2] List Networks"
        echo "[0] Exit"
        echo ""
        read -rp "Choose an option: " option

        case "$option" in
            1) _dockm_containers "$engine" ;;
            2) _dockm_networks "$engine" ;;
            0|"") break ;;
            *) echo "❌ Invalid option." ;;
        esac
    done

    trap - INT
}

# =================== EXISTING FUNCTIONS

function docker_stop_all(){
  ${CONTAINER_ENGINE:-docker} stop $(${CONTAINER_ENGINE:-docker} ps -q)
}

function docker_networks(){
for network in $(${CONTAINER_ENGINE:-docker} network ls -q); do
  echo "Network ID: $network"
  ${CONTAINER_ENGINE:-docker} network inspect $network --format '{{.Name}}: {{range .IPAM.Config}}{{.Subnet}} (Gateway: {{.Gateway}}){{end}}'
done
}

# https://stackoverflow.com/questions/43181654/locating-data-volumes-in-docker-desktop-windows
function windockervolumes() {
    explorer "\\\wsl$\docker-desktop-data\data\docker\volumes"
}

# --- BACKUP

# Usage: $0 docker_backup_volume <volume_name> <backup_path>"
#       docker_restore_volume <volume_name> <backup_path>"

# Function to back up a volume
docker_backup_volume() {
  local volume_name=$1
  local backup_path=$2

  # Create a temporary container to access the volume
  local container_id=$(${CONTAINER_ENGINE:-docker} run --rm -d \
    -v ${volume_name}:/volume \
    alpine:latest tail -f /dev/null)

  if [ -z "$container_id" ]; then
    echo "Error: Failed to create a temporary container."
    exit 1
  fi

  echo "Backing up volume '${volume_name}' to '${backup_path}'..."
  # Create the backup
  ${CONTAINER_ENGINE:-docker} exec $container_id tar -czf /backup.tar.gz -C /volume .
  # Copy the backup archive to the host
  ${CONTAINER_ENGINE:-docker} cp $container_id:/backup.tar.gz ${backup_path}
  # Clean up
  ${CONTAINER_ENGINE:-docker} stop $container_id >/dev/null
  echo "Backup completed successfully. File saved at '${backup_path}'."
}

# Function to restore a volume
docker_restore_volume() {
  local volume_name=$1
  local backup_path=$2

  if [ ! -f "$backup_path" ]; then
    echo "Error: Backup file '${backup_path}' not found."
    exit 1
  fi

  # Create a temporary container to restore the volume
  local container_id=$(${CONTAINER_ENGINE:-docker} run --rm -d \
    -v ${volume_name}:/volume \
    alpine:latest tail -f /dev/null)

  if [ -z "$container_id" ]; then
    echo "Error: Failed to create a temporary container."
    exit 1
  fi

  echo "Restoring backup from '${backup_path}' to volume '${volume_name}'..."
  # Copy the backup archive to the container
  ${CONTAINER_ENGINE:-docker} cp ${backup_path} $container_id:/backup.tar.gz
  # Extract the backup into the volume
  ${CONTAINER_ENGINE:-docker} exec $container_id tar -xzf /backup.tar.gz -C /volume
  # Clean up
  ${CONTAINER_ENGINE:-docker} stop $container_id >/dev/null
  echo "Restore completed successfully."
}

# =================== BACKUP ALL DOCKER FUNCTIONS

# Backup all Docker volumes using your existing function
docker_backup_all_volumes() {
  local backup_dir=$1

  if [ -z "$backup_dir" ]; then
    echo "Usage: docker_backup_all_volumes <backup_directory>"
    return 1
  fi

  mkdir -p "$backup_dir"

  echo "🔍 Finding all Docker volumes..."
  local volumes=$(${CONTAINER_ENGINE:-docker} volume ls -q)

  if [ -z "$volumes" ]; then
    echo "No Docker volumes found to back up."
    return 0
  fi

  for volume in $volumes; do
    local backup_path="${backup_dir}/${volume}.tar.gz"
    echo "🧩 Backing up volume: $volume"
    docker_backup_volume "$volume" "$backup_path"
  done

  echo "✅ All Docker volumes have been backed up to '$backup_dir'."
}

# Restore all Docker volumes using your existing function
docker_restore_all_volumes() {
  local backup_dir=$1

  if [ -z "$backup_dir" ]; then
    echo "Usage: docker_restore_all_volumes <backup_directory>"
    return 1
  fi

  echo "🔍 Looking for backup files in '$backup_dir'..."
  local backups=$(find "$backup_dir" -type f -name "*.tar.gz")

  if [ -z "$backups" ]; then
    echo "No backup files found in '$backup_dir'."
    return 0
  fi

  for backup_file in $backups; do
    local filename=$(basename -- "$backup_file")
    local volume_name="${filename%.tar.gz}"

    # Create the volume if it doesn't exist
    ${CONTAINER_ENGINE:-docker} volume inspect "$volume_name" >/dev/null 2>&1 || ${CONTAINER_ENGINE:-docker} volume create "$volume_name"

    echo "📦 Restoring volume: $volume_name from $backup_file"
    docker_restore_volume "$volume_name" "$backup_file"
  done

  echo "✅ All Docker volumes have been restored from '$backup_dir'."
}
