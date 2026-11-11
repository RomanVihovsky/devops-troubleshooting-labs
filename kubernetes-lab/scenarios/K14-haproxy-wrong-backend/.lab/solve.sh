nx k8s-gw "sed -i -E 's/^(\s*server k8s-cp1 )192\.168\.56\.22:6443/\1192.168.56.21:6443/' /etc/haproxy/haproxy.cfg \
  && haproxy -c -q -f /etc/haproxy/haproxy.cfg && systemctl reload haproxy" </dev/null
retry 120 nodes_ready || true
