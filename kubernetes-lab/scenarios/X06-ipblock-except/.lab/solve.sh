python3 - egress.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p))
d["spec"]["egress"][1] = {"to": [{"ipBlock": {"cidr": "192.168.56.20/32"}}], "ports": [{"protocol": "TCP", "port": 8080}]}
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
kx apply -f egress.yaml >/dev/null
