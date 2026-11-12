python3 - log-agent.yaml <<'PY'
import sys, yaml
p = sys.argv[1]; d = yaml.safe_load(open(p))
d["spec"]["template"]["spec"]["tolerations"] = [{"key": "maintenance", "operator": "Exists", "effect": "NoExecute"}]
yaml.safe_dump(d, open(p, "w"), sort_keys=False)
PY
kx apply -f log-agent.yaml >/dev/null
kx -n logging rollout status ds/log-agent --timeout=120s >/dev/null || true
