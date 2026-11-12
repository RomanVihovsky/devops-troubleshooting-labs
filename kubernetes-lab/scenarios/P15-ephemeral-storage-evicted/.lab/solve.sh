python3 - thumbs.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p))
s = d["spec"]["template"]["spec"]; c = s["containers"][0]
c["volumeMounts"] = [{"name": "cache", "mountPath": "/tmp/cache"}]
c["resources"]["limits"]["ephemeral-storage"] = "600Mi"
s["volumes"] = [{"name": "cache", "emptyDir": {"sizeLimit": "512Mi"}}]
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
kx apply -f thumbs.yaml >/dev/null
wait_rollout thumbs deploy/thumbs 180 || true
kx -n thumbs delete pods --field-selector=status.phase=Failed >/dev/null 2>&1 || true
