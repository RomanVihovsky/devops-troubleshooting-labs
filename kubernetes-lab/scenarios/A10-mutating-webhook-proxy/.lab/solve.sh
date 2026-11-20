# the fix for everyone: the webhook also injects NO_PROXY for cluster-internal destinations
python3 - egress-guard.yaml <<'PY'
import json, sys, yaml
p = sys.argv[1]; docs = list(yaml.safe_load_all(open(p)))
env = docs[0]["spec"]["template"]["spec"]["containers"][0]["env"]
for e in env:
    if e["name"] == "WEBHOOK_PATCH":
        ops = json.loads(e["value"])
        ops.append({"op": "add", "path": "/spec/containers/{c}/env/-",
                    "value": {"name": "NO_PROXY", "value": ".svc,.cluster.local,10.96.0.0/12,localhost"}})
        e["value"] = json.dumps(ops)
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
ka -f egress-guard.yaml
wait_rollout security-system deploy/egress-guard
kx -n wallet rollout restart deploy/wallet >/dev/null
wait_rollout wallet deploy/wallet 240
