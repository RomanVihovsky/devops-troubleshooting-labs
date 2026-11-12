args() { kx -n kube-system get deploy metrics-server -o jsonpath='{.spec.template.spec.containers[0].args}'; }
top4() { [ "$(kx top nodes --no-headers 2>/dev/null | wc -l)" = 4 ]; }
internal_first() { args | jq -e 'map(select(startswith("--kubelet-preferred-address-types="))) | length == 1 and (.[0] | split("=")[1] | startswith("InternalIP"))' >/dev/null; }
verified() { ! args | grep -q -- '--kubelet-insecure-tls'; }
check_eventually 180 "kubectl top nodes lists 4 nodes" top4
check "metrics-server prefers InternalIP" internal_first
check "kubelet TLS still verified (no --kubelet-insecure-tls)" verified
verdict
