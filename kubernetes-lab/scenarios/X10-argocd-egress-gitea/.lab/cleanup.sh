# the hardening policy (and any the student added for repo-server) - the chart's own policies are Ingress-only
for p in $(kx -n argocd get networkpolicy -o json | jq -r '.items[] | select((.spec.policyTypes // []) | index("Egress")) | .metadata.name'); do
  kx -n argocd delete networkpolicy "$p" --ignore-not-found >/dev/null
done
for a in lab-apps demo shop; do argo_refresh "$a"; done
true
