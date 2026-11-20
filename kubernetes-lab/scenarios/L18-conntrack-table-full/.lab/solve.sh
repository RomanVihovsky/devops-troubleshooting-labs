nx k8s-w3 'rm -f /etc/sysctl.d/80-conntrack.conf; sysctl -q -w net.netfilter.nf_conntrack_max=131072' </dev/null
