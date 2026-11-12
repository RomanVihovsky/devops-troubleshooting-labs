render() { kx kustomize "$WS/O08/overlays/prod" 2>/dev/null; }
rendered_ok() { render | python3 -c 'import sys, yaml
d = [o for o in yaml.safe_load_all(sys.stdin) if o and o.get("kind") == "Deployment"][0]
env = {e["name"]: e.get("value") for e in d["spec"]["template"]["spec"]["containers"][0].get("env", [])}
sys.exit(0 if d["spec"]["replicas"] == 3 and env.get("LOG_LEVEL") == "info" else 1)'; }
live_ok() { [ "$(kx -n kust-prod get deploy web -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="LOG_LEVEL")].value}')" = info ]; }
base_kept() { grep -q 'replicas: 1' "$WS/O08/base/deployment.yaml" && grep -q 'value: debug' "$WS/O08/base/deployment.yaml"; }
check "the prod overlay renders 3 replicas and LOG_LEVEL=info" rendered_ok
check_eventually 120 "kust-prod/web: 3 Ready pods" deploy_ready kust-prod web 3
check "kust-prod/web runs with LOG_LEVEL=info" live_ok
check "the base still has the dev defaults" base_kept
verdict
