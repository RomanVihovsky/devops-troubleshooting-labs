python3 - policy.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p))
d["spec"]["egress"].append({"to": [{"ipBlock": {"cidr": "192.168.56.20/32"}}], "ports": [{"protocol": "TCP", "port": 3000}]})
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
kx apply -f policy.yaml >/dev/null
for a in lab-apps demo shop; do argo_refresh "$a"; done
retry 180 argo_app_ok demo || true
