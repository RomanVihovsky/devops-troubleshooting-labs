ready_cp() { [ "$(kx -n kube-system get pod "$1-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
fresh_deploy() {
  local n="lab-b02-$RANDOM" r=1
  kx -n ops create deployment "$n" --image=registry.lab:5000/lab/labapp:1.4 --replicas=1 >/dev/null 2>&1 || return 1
  running() { [ "$(kx -n ops get pods -l app="$n" --field-selector=status.phase=Running -o name 2>/dev/null | wc -l)" -ge 1 ]; }
  retry 60 running && r=0
  kx -n ops delete deployment "$n" --wait=false >/dev/null 2>&1; return $r
}
check_eventually 120 "the scheduler is Ready" ready_cp kube-scheduler
check_eventually 120 "the controller-manager is Ready" ready_cp kube-controller-manager
check_eventually 180 "all nodes Ready" nodes_ready
check "a new Deployment gets a ReplicaSet and a Running pod" fresh_deploy
check "the API answers" kx get --raw /readyz
verdict
