creates() { kx -n orders create deployment lab-a09-probe --image=registry.lab:5000/lab/labapp:1.4 --dry-run=server >/dev/null 2>&1; }
enforced() {
  local o; o=$(kx -n orders run lab-a09-deny --image=registry.lab:5000/lab/labapp:1.4 --labels=policy.lab/deny=true --dry-run=server 2>&1) && return 1
  grep -q 'not allowed in this namespace' <<<"$o"
}
closed() {
  kx get validatingwebhookconfiguration pod-policy -o json | jq -e '.webhooks[] | select(.name == "pods.policy.lab")
    | .failurePolicy == "Fail" and .namespaceSelector.matchLabels.policy == "enforced"' >/dev/null
}
labelled() { [ "$(kx get ns orders -o jsonpath='{.metadata.labels.policy}')" = enforced ]; }
check_eventually 90 "objects can be created in orders again" creates
check "the webhook still rejects objects labelled policy.lab/deny=true in orders" enforced
check "pod-policy still fails closed (failurePolicy: Fail) for policy=enforced namespaces" closed
check "orders is still labelled policy=enforced" labelled
verdict
