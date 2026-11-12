job_done() { kx -n orders get jobs -o json | jq -e '[.items[] | select(.status.succeeded >= 1
  and ((.spec.template.spec.containers[0].command // []) + (.spec.template.spec.containers[0].args // []) | join(" ") | test("migrate")))] | length > 0' >/dev/null; }
# no pod that always restarts (Deployment/RS/StatefulSet/DaemonSet) runs "migrate"
no_loop() { ! kx -n orders get deploy,statefulset,daemonset -o json | jq -e '[.items[] | .spec.template.spec.containers[]
  | ((.command // []) + (.args // [])) | join(" ") | select(test("migrate"))] | length > 0' >/dev/null; }
check_eventually 120 "a Job ran labapp migrate and Completed" job_done
check "no Deployment/StatefulSet/DaemonSet runs the migration" no_loop
check_eventually 60 "orders: 2 Ready pods" deploy_ready orders orders 2
verdict
