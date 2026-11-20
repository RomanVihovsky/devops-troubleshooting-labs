python3 - image-scanner.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = list(yaml.safe_load_all(open(p)))
docs[0]["spec"]["template"]["spec"]["dnsConfig"] = {"options": [{"name": "ndots", "value": "1"}]}
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
ka -f image-scanner.yaml
wait_rollout scanner deploy/image-scanner
