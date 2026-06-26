
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
