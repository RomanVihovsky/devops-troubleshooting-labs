required_kept() { kx -n billing get deploy billing -o json | jq -e '[.spec.template.spec.containers[0].env[] | select(.name == "REQUIRED_ENV" and (.value | test("DATABASE_URL")))] | length == 1' >/dev/null; }
check_eventually 120 "billing rollout complete, all replicas Ready" deploy_ready billing billing
check_eventually 120 "no new restarts for 60 s" stable_for 60 billing app=billing
check "REQUIRED_ENV still demands DATABASE_URL" required_kept
verdict
