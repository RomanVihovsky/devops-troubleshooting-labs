cd "$LAB_DIR/workspace/gitops" || die "no workspace/gitops"
git pull -q
python3 - <<'PY'
import yaml
app = yaml.safe_load(open("../T11/t11.yaml"))
app["metadata"]["finalizers"] = ["resources-finalizer.argocd.argoproj.io"]
app["spec"]["project"] = "lab"
app["spec"]["source"]["path"] = "charts/labapp"
app["spec"]["destination"]["namespace"] = "t11"
app["spec"]["syncPolicy"]["automated"] = {"prune": True, "selfHeal": True}
yaml.safe_dump(app, open("apps/t11.yaml", "w"), sort_keys=False)
p = yaml.safe_load(open("apps/project-lab.yaml"))
p["spec"]["destinations"].append({"server": "https://kubernetes.default.svc", "namespace": "t11"})
yaml.safe_dump(p, open("apps/project-lab.yaml", "w"), sort_keys=False)
PY
git add apps/t11.yaml apps/project-lab.yaml
git commit -qm "t11: new app, allowed in project lab"
git push -q origin main 2>/dev/null
argo_refresh lab-apps
exists() { kx -n argocd get application t11 >/dev/null 2>&1; }
retry 120 exists || die "lab-apps did not create t11"
argo_refresh t11
retry 240 argo_app_ok t11 || die "t11 not Synced + Healthy"
