ready_pods() { kx -n thumbs get pods -l app=thumbs -o json | jq -r '.items[] | select(any(.status.conditions[]?; .type == "Ready" and .status == "True")) | .spec.nodeName'; }
two_nodes() { [ "$(ready_pods | sort -u | grep -c .)" -ge 2 ]; }
own_pvcs() {
  kx -n thumbs get pods -l app=thumbs -o json | jq -e '[.items[] | [.spec.volumes[]? | .persistentVolumeClaim.claimName // empty]] | (length >= 2) and (map(.[0]) | unique | length) == length' >/dev/null \
    && [ "$(kx -n thumbs get pvc -o json | jq '[.items[] | select(.status.phase == "Bound" and .spec.storageClassName == "local-path")] | length')" -ge 2 ]
}
check_eventually 150 "2 thumbs pods Ready on two different nodes" two_nodes
check "each pod has its own local-path PVC" own_pvcs
verdict
