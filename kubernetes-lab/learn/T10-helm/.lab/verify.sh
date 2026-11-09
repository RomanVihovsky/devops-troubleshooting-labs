hist() { helm -n t10 history web -o json 2>/dev/null; }
rolled_back() { hist | jq -e 'last | .status == "deployed" and (.description | test("Rollback to 1"))' >/dev/null; }
had_failure() { hist | jq -e 'any(.[]; .status == "failed")' >/dev/null; }
runs_13() { [ "$(kx -n t10 get deploy -l app.kubernetes.io/instance=web -o jsonpath='{.items[0].spec.template.spec.containers[0].image}' 2>/dev/null)" = registry.lab:5000/lab/labapp:1.3 ]; }
ready2() { [ "$(kx -n t10 get deploy -l app.kubernetes.io/instance=web -o jsonpath='{.items[0].status.readyReplicas}' 2>/dev/null)" = 2 ]; }
n_secrets() { kx -n t10 get secrets -l owner=helm,name=web --no-headers 2>/dev/null | wc -l; }
chart_v() { awk '/^version:/ { print $2 }' "$LAB_DIR/charts/labapp/Chart.yaml"; }
check "release web: the current revision is \"Rollback to 1\" and deployed" rolled_back
check "release web: the history has a failed revision" had_failure
check "the Deployment runs labapp 1.3" runs_13
check_eventually 120 "2 ready replicas" ready2
check "answers: number of release Secrets" answered release_secrets "$(n_secrets)"
check "answers: chart version in the release" answered chart_version "$(chart_v)"
verdict
