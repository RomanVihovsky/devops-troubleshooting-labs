# D02: a change freeze turns self-heal off (in Git), then someone edits the live Deployment
gitops_commit "change freeze until the Q4 release: no self-heal for demo (INC-2210)" <<'SNIP'
sed -i 's/automated: {prune: true, selfHeal: true}/automated: {prune: true, selfHeal: false}/' apps/demo.yaml
grep -q 'selfHeal: false' apps/demo.yaml
SNIP
argo_refresh lab-apps
selfheal_off() { [ "$(kx -n argocd get application demo -o jsonpath='{.spec.syncPolicy.automated.selfHeal}')" = false ]; }
retry 180 selfheal_off || die "the freeze did not reach the demo Application"
kx -n demo scale deploy demo --replicas=5 >/dev/null
kx -n demo set env deploy/demo GREETING="hotfix-do-not-touch" >/dev/null
argo_refresh demo
out_of_sync() { [ "$(kx -n argocd get application demo -o jsonpath='{.status.sync.status}')" = OutOfSync ]; }
retry 120 out_of_sync || die "demo did not show OutOfSync"
