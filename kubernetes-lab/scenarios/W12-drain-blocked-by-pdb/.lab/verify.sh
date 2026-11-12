evicted() { ! kx -n ha get pod "$(recall w12_pod)" >/dev/null 2>&1; }
schedulable() { [ "$(kx get node k8s-w1 -o jsonpath='{.spec.unschedulable}')" != true ]; }
pdb_ok() { kx -n ha get pdb -o json | jq -e '[.items[] | select(.spec.selector.matchLabels.app == "ha-api"
  and ((.spec.minAvailable == 2) or (.spec.minAvailable == "67%") or (.spec.maxUnavailable == 1)))] | length >= 1' >/dev/null; }
check "the ha-api pod from k8s-w1 was evicted" evicted
check "k8s-w1 is schedulable again" schedulable
check_eventually 150 "ha-api: 3 Ready pods" deploy_ready ha ha-api 3
check "a PDB for ha-api still guarantees 2 available (minAvailable 2 or maxUnavailable 1)" pdb_ok
verdict
