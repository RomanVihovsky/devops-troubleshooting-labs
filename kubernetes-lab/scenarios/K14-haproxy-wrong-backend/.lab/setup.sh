# K14: haproxy's API backend points at the reserved cp2 address (no VM there)
nx k8s-gw "sed -i -E 's/^(\s*server k8s-cp1 )192\.168\.56\.21:6443/\1192.168.56.22:6443/' /etc/haproxy/haproxy.cfg \
  && grep -qE '^\s*server k8s-cp1 192\.168\.56\.22:6443' /etc/haproxy/haproxy.cfg && haproxy -c -q -f /etc/haproxy/haproxy.cfg \
  && systemctl restart haproxy" </dev/null   # restart: a reload keeps the kubelets' open connections on the old process
api_down() { ! KX_TIMEOUT=5s kx get --raw /readyz >/dev/null 2>&1; }
retry 60 api_down || die "the API still answers through haproxy"
# cp1's own API (its certificate includes 192.168.56.21): some worker turns NotReady
local_kx() { nx "$CP" "kubectl --kubeconfig /etc/kubernetes/admin.conf --server https://192.168.56.21:6443 --request-timeout=10s $*" </dev/null; }
notready() { local_kx get nodes --no-headers | awk '$2 != "Ready"' | grep -q .; }
retry 180 notready || die "no node went NotReady"
