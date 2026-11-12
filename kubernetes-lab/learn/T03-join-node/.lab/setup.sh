# T03: k8s-w3 leaves the cluster the clean way; the student joins it back by hand
kx drain k8s-w3 --ignore-daemonsets --delete-emptydir-data --force --disable-eviction --timeout=120s >/dev/null 2>&1 || true
kx delete node k8s-w3 >/dev/null
nxi k8s-w3 >/dev/null 2>&1 <<'__X__' || true
kubeadm reset -f
rm -rf /etc/cni/net.d/* /etc/kubernetes/kubeadm /var/lib/calico /var/run/calico
ip link del vxlan.calico 2>/dev/null
iptables -F; iptables -t nat -F; iptables -t mangle -F; iptables -X; iptables -t nat -X; iptables -t mangle -X
true
__X__
gone() { ! kx get node k8s-w3 >/dev/null 2>&1; }
retry 60 gone || die "k8s-w3 is still registered"
