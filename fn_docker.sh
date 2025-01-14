
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