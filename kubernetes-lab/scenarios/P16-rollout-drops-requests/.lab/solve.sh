python3 - checkout-api.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = list(yaml.safe_load_all(open(p)))
c = docs[0]["spec"]["template"]["spec"]["containers"][0]
c["lifecycle"] = {"preStop": {"exec": {"command": ["sleep", "10"]}}}
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
ka -f checkout-api.yaml
wait_rollout checkout deploy/checkout-api 240
