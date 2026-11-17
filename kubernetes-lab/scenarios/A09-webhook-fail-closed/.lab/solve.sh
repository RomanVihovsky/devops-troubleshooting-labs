python3 - pod-policy.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = list(yaml.safe_load_all(open(p)))
docs[0]["spec"]["template"]["spec"]["containers"][0]["readinessProbe"]["httpGet"]["scheme"] = "HTTPS"
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
ka -f pod-policy.yaml
wait_rollout policy-system deploy/pod-policy
