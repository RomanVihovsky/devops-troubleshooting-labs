# K15: w3 drained, deleted and reset (as in T03); the "wiki" join command has an expired token and the CA hash
# of an old cluster
kx drain k8s-w3 --ignore-daemonsets --delete-emptydir-data --force --disable-eviction --timeout=120s >/dev/null 2>&1 || true
kx delete node k8s-w3 >/dev/null
nxi k8s-w3 >/dev/null 2>&1 <<'__X__' || true
kubeadm reset -f
rm -rf /etc/cni/net.d/* /etc/kubernetes/kubeadm /var/lib/calico /var/run/calico
: > /etc/default/kubelet
ip link del vxlan.calico 2>/dev/null
iptables -F; iptables -t nat -F; iptables -t mangle -F; iptables -X; iptables -t nat -X; iptables -t mangle -X
true
__X__
gone() { ! kx get node k8s-w3 >/dev/null 2>&1; }
retry 60 gone || die "k8s-w3 is still registered"
# a token that expires at once (the token cleaner deletes it), and the hash of a CA that isn't this cluster's
tok=$(nx "$CP" 'kubeadm token create --ttl 1s --description "wiki example"' </dev/null)
d=$(mktemp -d); openssl genrsa -out "$d/k" 2048 2>/dev/null
hash=$(openssl rsa -in "$d/k" -pubout -outform der 2>/dev/null | sha256sum | cut -d' ' -f1); rm -rf "$d"
cat > join-command.txt <<TXT
# From the wiki page "Adding workers" (last edited 4 months ago). Run on the new node as root:
kubeadm join k8s-api.lab:6443 --token $tok --discovery-token-ca-cert-hash sha256:$hash
TXT
expired() { ! nx "$CP" 'kubeadm token list 2>/dev/null' </dev/null | awk 'NR > 1 { print $1 }' | grep -qx "$tok"; }
retry 120 expired || true
