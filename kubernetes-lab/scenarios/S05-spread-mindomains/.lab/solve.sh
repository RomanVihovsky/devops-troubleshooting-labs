python3 - search-api.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p))
for c in d["spec"]["template"]["spec"]["topologySpreadConstraints"]:
    c.pop("minDomains", None)
    c["matchLabelKeys"] = ["pod-template-hash"]   # spread each ReplicaSet on its own during rollouts
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
ka -f search-api.yaml
wait_rollout search deploy/search-api 180
