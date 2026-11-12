no_cmp_error() { ! kx -n argocd get application "$1" -o json | jq -e '[.status.conditions[]? | select(.type == "ComparisonError")] | length > 0' >/dev/null; }
app_good() { argo_app_ok "$1" && no_cmp_error "$1"; }
# Egress policies in argocd whose podSelector matches the repo-server pod's labels
rs_policies() {
  local labels; labels=$(kx -n argocd get pods -l app.kubernetes.io/name=argocd-repo-server -o json | jq -c '.items[0].metadata.labels')
  kx -n argocd get networkpolicy -o json | jq -c --argjson l "$labels" '[.items[] | select((.spec.policyTypes // []) | index("Egress"))
    | select((.spec.podSelector.matchLabels // {}) as $m | all($m | to_entries[]; $l[.key] == .value))
    | select((.spec.podSelector.matchExpressions // []) | length == 0)]'
}
hardened() { rs_policies | jq -e 'length > 0' >/dev/null; }
not_open() { ! rs_policies | jq -e '[.[].spec.egress[]? | select((.to // []) == [] or ([.to[]?.ipBlock.cidr // empty] | index("0.0.0.0/0")))] | length > 0' >/dev/null; }
for a in lab-apps demo shop; do argo_refresh "$a"; done
for a in lab-apps demo shop; do check_eventually 180 "$a Synced + Healthy, no ComparisonError" app_good "$a"; done
check "an Egress NetworkPolicy still selects repo-server" hardened
check "...and none of them allows all egress" not_open
verdict
