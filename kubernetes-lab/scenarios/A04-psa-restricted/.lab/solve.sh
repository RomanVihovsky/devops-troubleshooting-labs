python3 - reporter.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p)); s = d["spec"]["template"]["spec"]
s["securityContext"] = {"runAsNonRoot": True, "seccompProfile": {"type": "RuntimeDefault"}}
s["containers"][0]["securityContext"] = {"allowPrivilegeEscalation": False, "capabilities": {"drop": ["ALL"]}}
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
kx apply -f reporter.yaml >/dev/null
wait_rollout secure-apps deploy/reporter 120
