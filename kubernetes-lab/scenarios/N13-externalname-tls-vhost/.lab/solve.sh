python3 - frontend.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = list(yaml.safe_load_all(open(p)))
for d in docs:
    if d["kind"] == "Deployment":
        for e in d["spec"]["template"]["spec"]["containers"][0]["env"]:
            if e["name"] == "UPSTREAM_URL":
                e["value"] = "https://search.vendor.svc:8443/items"
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
ka -f frontend.yaml
wait_rollout frontend deploy/frontend 180
