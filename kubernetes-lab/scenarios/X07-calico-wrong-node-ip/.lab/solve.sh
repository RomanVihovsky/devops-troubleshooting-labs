kx -n kube-system patch ds calico-node --type strategic -p '{"spec":{"updateStrategy":{"type":"RollingUpdate","rollingUpdate":{"maxUnavailable":1}},"template":{"spec":{"containers":[{"name":"calico-node","env":[{"name":"IP_AUTODETECTION_METHOD","value":"cidr=192.168.56.0/24"}]}]}}}}' >/dev/null
kx -n kube-system rollout status ds/calico-node --timeout=300s >/dev/null 2>&1 || true
ok() { [ "$(kx get node k8s-w3 -o jsonpath='{.metadata.annotations.projectcalico\.org/IPv4Address}')" = 192.168.56.33/24 ]; }
retry 180 ok || true
