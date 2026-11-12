api_up() { [ "$(kx get --raw /readyz 2>/dev/null)" = ok ]; }
backend() { nx k8s-gw "grep -E '^\s*server ' /etc/haproxy/haproxy.cfg" </dev/null | grep -q '192.168.56.21:6443' \
            && ! nx k8s-gw "grep -E '^\s*server ' /etc/haproxy/haproxy.cfg" </dev/null | grep -q '192.168.56.22'; }
up() { curl -s --max-time 5 'http://192.168.56.20:8404/;csv' | awk -F, '$1 == "k8s-control-plane" && $2 != "BACKEND" && $2 != "FRONTEND" { print $18 }' | grep -qx UP; }
check_eventually 90 "kubectl from the desktop (https://192.168.56.20:6443)" api_up
check "haproxy backend: 192.168.56.21:6443 (no 192.168.56.22)" backend
check_eventually 60 "haproxy reports the API server UP" up
check_eventually 180 "all nodes Ready" nodes_ready
verdict
