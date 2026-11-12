gitops_commit "team-a: allow namespace payments (INC-2252)" student <<'SNIP'
sed -i 's/namespace: payment}/namespace: payments}/' apps/project-team-a.yaml
grep -q 'namespace: payments}' apps/project-team-a.yaml
SNIP
argo_refresh lab-apps
retry 120 kx -n argocd get appproject team-a -o jsonpath='{.spec.destinations[?(@.namespace=="payments")].namespace}' || true
argo_refresh payments
retry 240 argo_app_ok payments || true
