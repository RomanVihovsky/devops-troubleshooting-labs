cat >> pricing.yaml <<'YML'
---
apiVersion: v1
kind: ConfigMap
metadata: {name: pricing-config-v2, namespace: pricing}
immutable: true
data:
  CURRENCY: USD
  APP_NAME: pricing
YML
python3 - pricing.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = [d for d in yaml.safe_load_all(open(p)) if d]
docs = [d for d in docs if not (d["kind"] == "ConfigMap" and d["metadata"]["name"] == "pricing-config")]
for d in docs:
    if d["kind"] == "Deployment":
        d["spec"]["template"]["spec"]["containers"][0]["envFrom"] = [{"configMapRef": {"name": "pricing-config-v2"}}]
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
kx apply -f pricing.yaml >/dev/null
wait_rollout pricing deploy/pricing 180
