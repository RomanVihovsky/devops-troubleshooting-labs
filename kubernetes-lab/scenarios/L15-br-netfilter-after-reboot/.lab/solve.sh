nx k8s-w3 "grep -qx br_netfilter /etc/modules-load.d/k8s.conf || echo br_netfilter >> /etc/modules-load.d/k8s.conf; modprobe br_netfilter; sysctl -q --system" </dev/null
