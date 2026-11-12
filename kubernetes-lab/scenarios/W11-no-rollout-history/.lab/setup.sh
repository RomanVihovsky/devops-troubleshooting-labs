# W11: revisionHistoryLimit 0; a release (1.3 -> 1.4 + ERROR_RATE=1) that rolls out completely - its pods are Ready
# but every /items fails - so the 1.3 ReplicaSet is deleted and rollout undo has nothing
kns pay
kx -n pay create deployment checkout --image=registry.lab:5000/lab/labapp:1.3 --replicas=3 --dry-run=client -o yaml \
  | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); s = d["spec"]
s["revisionHistoryLimit"] = 0
s["template"]["spec"]["containers"][0]["readinessProbe"] = {"httpGet": {"path": "/ready", "port": 8080}, "periodSeconds": 3}
print(yaml.safe_dump(d))' | ka -f -
wait_rollout pay deploy/checkout
kx -n pay patch deploy checkout --type json -p '[
  {"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "registry.lab:5000/lab/labapp:1.4"},
  {"op": "add", "path": "/spec/template/spec/containers/0/env", "value": [{"name": "ERROR_RATE", "value": "1"}]}]' >/dev/null
wait_rollout pay deploy/checkout 180
only_14() { [ "$(kx -n pay get rs -l app=checkout -o jsonpath='{range .items[*]}{.spec.template.spec.containers[0].image}{"\n"}{end}')" = registry.lab:5000/lab/labapp:1.4 ]; }
retry 120 only_14 || die "the old ReplicaSet is still there"
! kx -n pay exec deploy/checkout -- labapp get http://localhost:8080/items >/dev/null 2>&1 || die "/items still works"
! kx -n pay rollout undo deploy/checkout --dry-run=server >/dev/null 2>&1 || die "rollout undo would work"
