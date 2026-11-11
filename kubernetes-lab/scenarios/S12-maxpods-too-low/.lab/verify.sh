running() { [ "$(kx -n reports get pods -l app=reports --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)" = 3 ]; }
cfg_ok() {   # maxPods unset (default 110) or >= 110 in the file, and the node reports it
  local w m
  for w in k8s-w1 k8s-w2 k8s-w3; do
    m=$(nx "$w" "python3 -c 'import yaml; print(yaml.safe_load(open(\"/var/lib/kubelet/config.yaml\")).get(\"maxPods\") or 110)'" </dev/null)
    [ "${m:-0}" -ge 110 ] || return 1
    [ "$(kx get node "$w" -o jsonpath='{.status.allocatable.pods}')" -ge 110 ] || return 1
  done
}
check_eventually 120 "every worker: maxPods >= 110 in its kubelet config and reported" cfg_ok
check_eventually 180 "reports: 3 Running pods" running
check_eventually 120 "all nodes Ready" nodes_ready
verdict
