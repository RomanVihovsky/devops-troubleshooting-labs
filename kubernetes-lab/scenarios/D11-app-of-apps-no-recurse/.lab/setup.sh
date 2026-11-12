# D11: a team's Application under apps/team/ - the root app-of-apps reads apps/ without recurse
gitops_commit "team observability: metrics app" "dev-olga" <<'SNIP'
mkdir -p apps/team envs/metrics
cat > envs/metrics/values.yaml <<'YML'
fullnameOverride: metrics
app:
  greeting: Metrics
YML
cat > apps/team/metrics.yaml <<'YML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: metrics
  namespace: argocd
spec:
  project: lab
  source:
    repoURL: http://git.lab:3000/lab/gitops.git
    targetRevision: main
    path: charts/labapp
    helm:
      releaseName: metrics
      valueFiles: [../../envs/metrics/values.yaml]
  destination:
    server: https://kubernetes.default.svc
    namespace: metrics
  syncPolicy:
    automated: {prune: true, selfHeal: true}
    syncOptions: [CreateNamespace=true]
YML
python3 - <<'PY'
p = "apps/project-lab.yaml"; s = open(p).read()
a = "    - {server: https://kubernetes.default.svc, namespace: shop}\n"
s = s.replace(a, a + "    - {server: https://kubernetes.default.svc, namespace: metrics}\n", 1)
open(p, "w").write(s)
PY
SNIP
argo_refresh lab-apps
seen() { [ "$(kx -n argocd get application lab-apps -o jsonpath='{.status.sync.revision}')" = "$(gx '/repos/lab/gitops/branches/main' | jq -r .commit.id)" ]; }
retry 180 seen || die "lab-apps did not pick up the commit"
retry 60 argo_app_ok lab-apps || die "lab-apps not Synced"
! kx -n argocd get application metrics >/dev/null 2>&1 || die "metrics exists already"
