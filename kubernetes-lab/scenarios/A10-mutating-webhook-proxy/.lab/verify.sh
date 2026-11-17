proxy_kept() {   # every live (not terminating) wallet pod, at least 2, has the injected proxy
  kx -n wallet get pods -l app=wallet -o json | jq -e '[.items[] | select(.metadata.deletionTimestamp == null)] as $p
    | ($p | length) >= 2 and ($p | all([.spec.containers[0].env[]? | select(.name == "HTTPS_PROXY" and (.value | contains("egress-proxy")))] | length > 0))' >/dev/null
}
still_mutates() {
  kx get mutatingwebhookconfiguration egress-guard -o json | jq -e '.webhooks[0] | .namespaceSelector.matchLabels.egress == "guarded"
    and (.rules[0].resources | index("pods")) != null' >/dev/null && [ "$(kx get ns wallet -o jsonpath='{.metadata.labels.egress}')" = guarded ]
}
check_eventually 180 "wallet: rollout complete, 2 Ready pods" deploy_ready wallet wallet 2
check_eventually 60 "the wallet pods still carry the injected HTTPS_PROXY" proxy_kept
check "egress-guard still mutates pods in namespace wallet" still_mutates
check_eventually 150 "wallet pods stay up: no restart for 60 s" stable_for 60 wallet app=wallet
verdict
