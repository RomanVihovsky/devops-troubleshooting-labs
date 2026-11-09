raw() { gx "/repos/lab/gitops/raw/$1?ref=main" 2>/dev/null; }
git_app() {
  raw apps/t11.yaml | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); s = d["spec"]
ok = d["metadata"]["name"] == "t11" and s["destination"]["namespace"] == "t11" and s["syncPolicy"]["automated"].get("selfHeal") is True
sys.exit(0 if ok else 1)'
}
git_project() { raw apps/project-lab.yaml | python3 -c 'import sys, yaml
d = yaml.safe_load(sys.stdin); sys.exit(0 if any(x.get("namespace") == "t11" for x in d["spec"]["destinations"]) else 1)'; }
from_root() { kx -n argocd get application t11 -o jsonpath='{.metadata.annotations.argocd\.argoproj\.io/tracking-id}' 2>/dev/null | grep -q '^lab-apps:'; }
replicas() { kx -n t11 get deploy t11 -o jsonpath='{.spec.replicas}' 2>/dev/null; }
reverted() { [ "$(replicas)" = 2 ]; }
self_heals() {
  [ "$(replicas)" = 2 ] || return 1
  kx -n t11 scale deploy t11 --replicas=4 >/dev/null 2>&1 || return 1
  retry 90 reverted
}
check "apps/t11.yaml on main: t11 -> namespace t11, automated + selfHeal" git_app
check "apps/project-lab.yaml on main permits namespace t11" git_project
check_eventually 120 "Application t11 exists, created by lab-apps (app-of-apps)" from_root
check_eventually 180 "t11 Synced + Healthy" argo_app_ok t11
check "a manual scale of t11 is reverted (self-heal)" self_heals
verdict
