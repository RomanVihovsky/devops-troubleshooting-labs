args=$(kx -n kube-system get deploy metrics-server -o json | jq -c '.spec.template.spec.containers[0].args
  | map(if startswith("--kubelet-preferred-address-types=") then "--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname" else . end)')
kx -n kube-system patch deploy metrics-server --type json -p "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/args\",\"value\":$args}]" >/dev/null
wait_rollout kube-system deploy/metrics-server 120 || true
t() { [ "$(kx top nodes --no-headers 2>/dev/null | wc -l)" = 4 ]; }
retry 120 t || true
