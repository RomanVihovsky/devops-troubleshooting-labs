python3 - widgets-crd.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p))
d["spec"]["versions"][0]["served"] = True
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
ka -f widgets-crd.yaml
v1_back() { kx get --raw /apis/example.lab/v1/namespaces/factory/widgets >/dev/null 2>&1; }
retry 60 v1_back || true
kx -n factory get widgets.v2.example.lab -o json | kx replace -f - >/dev/null
kx patch crd widgets.example.lab --subresource=status --type=merge -p '{"status":{"storedVersions":["v2"]}}' >/dev/null
retry 90 deploy_ready factory widget-reporter 1 || true
