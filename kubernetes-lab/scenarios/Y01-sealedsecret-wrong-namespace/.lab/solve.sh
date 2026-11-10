ct=$(tr -d '\n' < new-token.txt | kubeseal --raw --scope strict --namespace demo --name demo-auth --from-file=/dev/stdin)
gitops_commit "demo: reseal the rotated token for namespace demo (INC-2260)" student <<SNIP
sed -i "s|^\\(\\s*auth-token: \\).*|\\1$ct|" envs/demo/values.yaml
grep -q "$ct" envs/demo/values.yaml
SNIP
argo_refresh demo
synced() { [ "$(kx -n demo get sealedsecret demo-auth -o jsonpath='{.status.conditions[?(@.type=="Synced")].status}' 2>/dev/null)" = True ]; }
retry 180 synced || true
kx -n demo rollout status deploy/demo --timeout=180s >/dev/null 2>&1 || true
