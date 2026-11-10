ready_away() {
  [ "$(kx -n checkout get pods -l app=api -o json 2>/dev/null | jq '[.items[] | select(.spec.nodeName != "k8s-w2" and .metadata.deletionTimestamp == null
      and any(.status.conditions[]?; .type == "Ready" and .status == "True"))] | length')" -ge 3 ]
}
tol_ok() {
  kx -n checkout get deploy api -o json 2>/dev/null | jq -e '[.spec.template.spec.tolerations[]? | select(.key == "node.kubernetes.io/unreachable" or .key == "node.kubernetes.io/not-ready")]
    | length == 2 and all(.[]; .tolerationSeconds != null and .tolerationSeconds <= 120)' >/dev/null
}
three() { [ "$(kx -n checkout get deploy api -o jsonpath='{.spec.replicas}' 2>/dev/null)" = 3 ]; }
check "tolerations for unreachable + not-ready set to at most 120 s" tol_ok
check "api still runs 3 replicas" three
check_eventually 180 "3 ready api pods away from k8s-w2" ready_away
verdict
