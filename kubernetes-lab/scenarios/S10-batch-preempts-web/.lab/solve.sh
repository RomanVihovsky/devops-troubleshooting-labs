# preemptionPolicy is immutable: re-create the class with the same value (the running batch pod keeps its priority)
kx -n storefront delete job nightly-batch --ignore-not-found --wait=true >/dev/null
python3 - priority.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p)); d["preemptionPolicy"] = "Never"
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
kx delete priorityclass batch-high --ignore-not-found >/dev/null
ka -f priority.yaml
retry 150 deploy_ready storefront storefront 3 || true
