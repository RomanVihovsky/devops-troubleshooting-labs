# the node reset only removes nft table lab_fault
nx k8s-w3 'nft delete table inet host_firewall 2>/dev/null; true' </dev/null
