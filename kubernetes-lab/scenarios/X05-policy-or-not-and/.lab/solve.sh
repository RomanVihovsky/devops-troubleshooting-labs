python3 - allow-prometheus.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p))
src = d["spec"]["ingress"][0]["from"]
merged = {}
for item in src:
    merged.update(item)
d["spec"]["ingress"][0]["from"] = [merged]
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
ka -f allow-prometheus.yaml
