alias router_ips="arp -a"
alias read_active_conn="netstat -b"
alias list_active_conn="netstat -a"
alias open_ports="netstat -tulnp"
# TUNNELS
alias pi_vnctunn="ssh -N -L 5900:127.0.0.1:5900 $1"
# alias ollama_tun="ssh -i ~/.ssh/<key> -L 11434:localhost:11434 anon@192.168.0.8 -N"
alias ifconfig_debian="ip -c a s"

function cloudflare_enroll(){
	warp-cli registration new $1
}

function ssh_tunnel() {
 # 1 = local_port
 # 2 = remote_port
 # 3 = Server
 # e.g ssh -N -L 8082:127.0.0.1:5432 anon@136.243.17.195
 # e.g ssh -N -L 8082:127.0.0.1:5432 ssh_conf_ref
 ssh -N -L $1:127.0.0.1:$2 $3
}


whois() {
  local domain="$1"
  local whois_server="whois.iana.org"  # Default Whois server

  if [[ -z "$domain" ]]; then
    echo "Usage: whois_domain <domain>"
    return 1
  fi

  # Perform the Whois lookup using netcat (nc) and curl
  local response=$(echo "$domain" | nc "$whois_server" 43)

  # Print the response
  echo "$response"
}


whoisip() {
  local ip="$1"
  local whois_server="whois.arin.net"  # Default Whois server for IP addresses

  if [[ -z "$ip" ]]; then
    echo "Usage: whois_ip <ip_address>"
    return 1
  fi

  # Perform the Whois lookup using netcat (nc)
  local response=$(echo "$ip" | nc "$whois_server" 43)

  # Print the response
  echo "$response"
}


ufw_allow_cidr() {
  local cidr="$1"
  local port="$2"

  if [[ -z "$cidr" || -z "$port" ]]; then
    echo "Usage: ufw_allow_cidr <cidr_block> <port>"
    echo "Example: ufw_allow_cidr 192.168.1.0/24 22"
    return 1
  fi

  # Execute the UFW command
  sudo ufw allow from "$cidr" to any port "$port"
}