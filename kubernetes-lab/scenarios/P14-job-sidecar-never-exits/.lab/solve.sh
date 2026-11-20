python3 - nightly-report.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p)); s = d["spec"]["template"]["spec"]
shipper = next(c for c in s["containers"] if c["name"] == "shipper")
s["containers"] = [c for c in s["containers"] if c["name"] != "shipper"]
shipper["restartPolicy"] = "Always"
s["initContainers"] = [shipper]
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
kx -n reports delete job nightly-report --wait=true >/dev/null
ka -f nightly-report.yaml
done_() { [ "$(kx -n reports get job nightly-report -o jsonpath='{.status.conditions[?(@.type=="Complete")].status}' 2>/dev/null)" = True ]; }
retry 120 done_ || true
