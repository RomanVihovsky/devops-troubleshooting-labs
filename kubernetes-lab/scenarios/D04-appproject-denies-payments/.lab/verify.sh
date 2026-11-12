raw() { gx "/repos/lab/gitops/raw/$1?ref=main"; }
in_team_a() { [ "$(kx -n argocd get application payments -o jsonpath='{.spec.project}' 2>/dev/null)" = team-a ]; }
proj_git() { raw apps/project-team-a.yaml | python3 -c 'import sys, yaml
s = yaml.safe_load(sys.stdin)["spec"]
dst = [d.get("namespace") for d in s.get("destinations", [])]
ok = "payments" in dst and "*" not in dst and all("*" not in (d.get("server", "") + d.get("namespace", "")) for d in s["destinations"])
ok = ok and s.get("sourceRepos") == ["http://git.lab:3000/lab/gitops.git"]
sys.exit(0 if ok else 1)'; }
app_git() { raw apps/payments.yaml | grep -q 'project: team-a'; }
check_eventually 180 "payments Synced + Healthy" argo_app_ok payments
check "payments is still in project team-a" in_team_a
check "the fix is in Git: apps/payments.yaml keeps project team-a" app_git
check "team-a's project in Git: explicit destination payments, no wildcards, only this repo" proj_git
verdict
