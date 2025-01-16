alias router_ips="arp -a"
alias read_active_conn="netstat -b"
alias list_active_conn="netstat -a"
alias pi_vnctunn="ssh -N -L 5900:127.0.0.1:5900 $1"
# alias ollama_tun="ssh -i ~/.ssh/ollama -L 11434:localhost:11434 anon@192.168.0.8 -N"

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