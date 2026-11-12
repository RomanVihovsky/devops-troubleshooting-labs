# R02: metrics-server dials the kubelets by hostname - pods can't resolve k8s-w1 etc.
args=$(kx -n kube-system get deploy metrics-server -o json | jq -c '.spec.template.spec.containers[0].args
  | map(if startswith("--kubelet-preferred-address-types=") then "--kubelet-preferred-address-types=Hostname" else . end)')
# (strategy Recreate came with the "simplified" manifest - with 1 replica and maxUnavailable 25% (= 0) the old,
# working pod would otherwise keep serving next to the broken one)
kx -n kube-system patch deploy metrics-server --type json -p "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/args\",\"value\":$args},{\"op\":\"replace\",\"path\":\"/spec/strategy\",\"value\":{\"type\":\"Recreate\"}}]" >/dev/null
wait_rollout kube-system deploy/metrics-server 120 || true
broken() { ! kx top nodes >/dev/null 2>&1; }
retry 180 broken || die "kubectl top still works"
