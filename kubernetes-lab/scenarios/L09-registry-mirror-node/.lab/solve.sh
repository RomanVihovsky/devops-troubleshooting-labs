nx k8s-w1 "sed -i 's|registry.lab:5050|registry.lab:5000|g' /etc/containerd/certs.d/registry.lab:5000/hosts.toml" </dev/null
kx -n edge delete pod -l app=edge-cache --field-selector spec.nodeName=k8s-w1 --wait=false >/dev/null
ready3() { [ "$(kx -n edge get ds edge-cache -o jsonpath='{.status.numberReady}')" = 3 ]; }
retry 120 ready3 || true
