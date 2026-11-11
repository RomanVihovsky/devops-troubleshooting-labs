python3 - notifier.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = [d for d in yaml.safe_load_all(open(p)) if d]
for d in docs:
    if d["kind"] != "Deployment":
        continue
    s = d["spec"]["template"]["spec"]; c = s["containers"][0]
    c["env"] = [e for e in c["env"] if e["name"] != "UPSTREAM_TOKEN"] + [{"name": "UPSTREAM_TOKEN_FILE", "value": "/etc/notify/token"}]
    c["volumeMounts"] = [{"name": "token", "mountPath": "/etc/notify", "readOnly": True}]
    s["volumes"] = [{"name": "token", "secret": {"secretName": "api-token"}}]
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
kx apply -f notifier.yaml >/dev/null
wait_rollout notify deploy/notifier || true
