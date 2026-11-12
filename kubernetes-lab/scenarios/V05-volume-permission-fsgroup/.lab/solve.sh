python3 - uploads.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = [d for d in yaml.safe_load_all(open(p)) if d]
for d in docs:
    if d["kind"] == "Deployment":
        sc = d["spec"]["template"]["spec"]["securityContext"]
        sc["fsGroup"] = 1000; sc["fsGroupChangePolicy"] = "OnRootMismatch"
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
kx apply -f uploads.yaml >/dev/null
wait_rollout uploads deploy/uploads 180
