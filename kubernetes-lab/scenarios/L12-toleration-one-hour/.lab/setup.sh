# L12: 3 api pods spread over the workers (one on k8s-w2), 1 h tolerations; then k8s-w2 is cut off
kns checkout
ka -f api.yaml
wait_rollout checkout deploy/api
[ -n "$(kx -n checkout get pods -l app=api --field-selector spec.nodeName=k8s-w2 -o name)" ] || die "no api pod on k8s-w2"
fault_partition k8s-w2
unreach() { kx get node k8s-w2 -o jsonpath='{.spec.taints[*].key}' | grep -q node.kubernetes.io/unreachable; }
retry 180 unreach || die "k8s-w2 never became unreachable"
