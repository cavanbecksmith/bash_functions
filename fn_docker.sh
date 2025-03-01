
function docker_stop_all(){
  docker stop $(docker ps -q)
}

function docker_networks(){
for network in $(docker network ls -q); do
  echo "Network ID: $network"
  docker network inspect $network --format '{{.Name}}: {{range .IPAM.Config}}{{.Subnet}} (Gateway: {{.Gateway}}){{end}}'
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
  local container_id=$(docker run --rm -d \
    -v ${volume_name}:/volume \
    alpine:latest tail -f /dev/null)

  if [ -z "$container_id" ]; then
    echo "Error: Failed to create a temporary container."
    exit 1
  fi

  echo "Backing up volume '${volume_name}' to '${backup_path}'..."
  # Create the backup
  docker exec $container_id tar -czf /backup.tar.gz -C /volume .
  # Copy the backup archive to the host
  docker cp $container_id:/backup.tar.gz ${backup_path}
  # Clean up
  docker stop $container_id >/dev/null
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
  local container_id=$(docker run --rm -d \
    -v ${volume_name}:/volume \
    alpine:latest tail -f /dev/null)

  if [ -z "$container_id" ]; then
    echo "Error: Failed to create a temporary container."
    exit 1
  fi

  echo "Restoring backup from '${backup_path}' to volume '${volume_name}'..."
  # Copy the backup archive to the container
  docker cp ${backup_path} $container_id:/backup.tar.gz
  # Extract the backup into the volume
  docker exec $container_id tar -xzf /backup.tar.gz -C /volume
  # Clean up
  docker stop $container_id >/dev/null
  echo "Restore completed successfully."
}
