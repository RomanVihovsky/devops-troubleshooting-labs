all_ready() { [ "$(kx -n edge get ds edge-cache -o jsonpath='{.status.numberReady}/{.status.desiredNumberScheduled}' 2>/dev/null)" = 3/3 ]; }
w1_ready() { kx -n edge get pods -l app=edge-cache --field-selector spec.nodeName=k8s-w1 -o jsonpath='{.items[*].status.containerStatuses[*].ready}' | grep -qx true; }
config_ok() { nx k8s-w1 'grep -q "^server = \"http://registry.lab:5000\"" /etc/containerd/certs.d/registry.lab:5000/hosts.toml && ! grep -q 5050 /etc/containerd/certs.d/registry.lab:5000/hosts.toml' </dev/null; }
pull_ok() { nx k8s-w1 'crictl pull registry.lab:5000/lab/labapp:1.5 >/dev/null 2>&1' </dev/null; }
check_eventually 180 "edge-cache: 3/3 Ready" all_ready
check "the pod on k8s-w1 is Ready" w1_ready
check "w1's hosts.toml for registry.lab:5000 points at http://registry.lab:5000" config_ok
check "w1 pulls a registry.lab:5000 image" pull_ok
verdict
