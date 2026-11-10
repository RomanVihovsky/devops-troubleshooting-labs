want="registry.k8s.io/kube-scheduler:$(kx version -o json 2>/dev/null | jq -r .serverVersion.gitVersion)"
image_ok() { nx "$CP" "grep -q 'image: $want\$' /etc/kubernetes/manifests/kube-scheduler.yaml" </dev/null; }
sched_ready() { [ "$(kx -n kube-system get pod "kube-scheduler-$CP" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}' 2>/dev/null)" = True ]; }
batch_running() { [ "$(kx -n ops get pods -l app=batch --field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l)" = 2 ]; }
manifests4() { [ "$(nx "$CP" 'ls /etc/kubernetes/manifests | wc -l' </dev/null)" = 4 ]; }
check "kube-scheduler manifest uses $want" image_ok
check_eventually 120 "kube-scheduler Ready" sched_ready
check_eventually 120 "ops/batch: 2 Running pods" batch_running
check "only the 4 control-plane manifests" manifests4
verdict
