# the golden sysctl.d has no conntrack line: put the runtime value back (kube-proxy would, on its next start)
nx k8s-w3 'rm -f /etc/sysctl.d/80-conntrack.conf; sysctl -q -w net.netfilter.nf_conntrack_max=131072' </dev/null >/dev/null 2>&1
true
