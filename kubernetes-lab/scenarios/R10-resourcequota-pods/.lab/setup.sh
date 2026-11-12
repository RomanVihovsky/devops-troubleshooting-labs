# R10: ResourceQuota pods: 2, already used by legacy; notifier can't get a pod
kns sandbox
ka -f - <<'YML'
apiVersion: v1
kind: ResourceQuota
metadata: {name: sandbox, namespace: sandbox}
spec:
  hard: {pods: "2", requests.cpu: "2", requests.memory: 2Gi}
YML
for d in legacy:2 notifier:1; do
  kx -n sandbox create deployment "${d%%:*}" --image=registry.lab:5000/lab/labapp:1.4 --replicas="${d##*:}" --dry-run=client -o yaml \
    | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); d["spec"]["template"]["spec"]["containers"][0]["resources"] = {"requests": {"cpu": "50m", "memory": "64Mi"}}
print(yaml.safe_dump(d))' | ka -f -
  [ "${d%%:*}" = legacy ] && wait_rollout sandbox deploy/legacy
done
exceeded() { kx -n sandbox get events -o jsonpath='{.items[*].message}' | grep -q 'exceeded quota'; }
retry 60 exceeded || die "no quota rejection"
