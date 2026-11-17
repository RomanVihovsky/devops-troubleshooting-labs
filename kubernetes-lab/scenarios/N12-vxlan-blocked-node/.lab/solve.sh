nx k8s-w3 'nft insert rule inet host_firewall input ip saddr 192.168.56.0/24 udp dport 4789 accept comment "\"Calico VXLAN between nodes\""' </dev/null
