# X10: repo-server may only talk DNS - it can't reach Gitea on k8s-gw any more
ka -f policy.yaml
for a in lab-apps demo shop; do argo_refresh "$a"; done
broken() { kx -n argocd get application demo -o json | jq -e '[.status.conditions[]? | select(.type == "ComparisonError")] | length > 0' >/dev/null; }
retry 300 broken || die "Argo CD still reaches Gitea"
