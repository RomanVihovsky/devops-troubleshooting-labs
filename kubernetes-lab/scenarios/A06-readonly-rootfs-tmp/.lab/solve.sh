python3 - <<'PY'
import yaml
d = yaml.safe_load(open("invoices.yaml")); s = d["spec"]["template"]["spec"]
s["containers"][0]["volumeMounts"] = [{"name": "tmp", "mountPath": "/tmp"}]
s["volumes"] = [{"name": "tmp", "emptyDir": {}}]
yaml.safe_dump(d, open("invoices.yaml", "w"), sort_keys=False)
PY
kx apply -f invoices.yaml >/dev/null
wait_rollout invoices deploy/invoices
