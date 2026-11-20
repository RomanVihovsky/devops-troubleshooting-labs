python3 - catalog-api.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; docs = list(yaml.safe_load_all(open(p)))
hpa = next(d for d in docs if d["kind"] == "HorizontalPodAutoscaler")
hpa["spec"]["behavior"]["scaleDown"] = {"stabilizationWindowSeconds": 300}
yaml.safe_dump_all(docs, open(p, "w"), sort_keys=False)
PY
ka -f catalog-api.yaml
# the HPA keeps recommendations only as long as its longest window (it was 0): let one full burst cycle
# enter the new 300 s history before anybody measures
sleep 70
