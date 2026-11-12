python3 - catalog.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = [d for d in yaml.safe_load_all(open(p)) if d]
for d in docs:
    if d["kind"] == "Deployment":
        d["spec"]["template"]["spec"]["containers"][0]["volumeMounts"] = [{"name": "files", "mountPath": "/etc/labapp"}]
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
kx apply -f catalog.yaml >/dev/null
wait_rollout catalog deploy/catalog
