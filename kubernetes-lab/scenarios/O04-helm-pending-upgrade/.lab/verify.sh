st() { helm status web -n helmx -o json 2>/dev/null; }
deployed() { st | jq -e '.info.status == "deployed" and .config.app.greeting == "Hallo"' >/dev/null; }
hallo() { [ "$(pods_get helmx app.kubernetes.io/instance=web / | grep -c '^Hallo from')" -ge 2 ]; }
img() { [ "$(kx -n helmx get deploy web -o jsonpath='{.spec.template.spec.containers[0].image}')" = registry.lab:5000/lab/labapp:1.4 ]; }
# the current (last) revision is deployed - Helm keeps the killed revision's "pending-upgrade" record in the history
no_pending() { helm history web -n helmx -o json 2>/dev/null | jq -se '.[0] | length > 0 and (last | .status == "deployed")' >/dev/null; }
check "release web deployed with today's values (greeting Hallo)" deployed
check_eventually 150 "web: 2 Ready pods" deploy_ready helmx web 2
check_eventually 60 "the pods greet Hallo" hallo
check "image labapp:1.4" img
check "the release's current revision is deployed (no pending operation)" no_pending
verdict
