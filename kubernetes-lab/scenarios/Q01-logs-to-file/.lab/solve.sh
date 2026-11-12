python3 - invoicer.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = [d for d in yaml.safe_load_all(open(p)) if d]
for d in docs:
    if d["kind"] == "Deployment":
        s = d["spec"]["template"]["spec"]
        s["containers"][0]["volumeMounts"] = [{"name": "logs", "mountPath": "/var/log/labapp"}]
        s["containers"].append({"name": "ship-logs", "image": "registry.lab:5000/lab/labapp:1.4",
                                "args": ["ship-logs", "/var/log/labapp/app.log"],
                                "volumeMounts": [{"name": "logs", "mountPath": "/var/log/labapp"}]})
        s["volumes"] = [{"name": "logs", "emptyDir": {}}]
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
kx apply -f invoicer.yaml >/dev/null
wait_rollout billing2 deploy/invoicer 120
