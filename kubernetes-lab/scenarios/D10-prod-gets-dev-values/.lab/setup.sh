# D10: the prod Application lists [prod, dev] values files - Helm's last file wins, so prod renders dev's values
gitops_commit "web: shared defaults - prod reuses the dev file for common settings" <<'SNIP'
mkdir -p envs/web-prod envs/web-dev
cat > envs/web-prod/values.yaml <<'YML'
# web in production
fullnameOverride: web
replicaCount: 3
app:
  greeting: Welcome
  logLevel: info
YML
cat > envs/web-dev/values.yaml <<'YML'
# web for developers: one pod, chatty logs
fullnameOverride: web
replicaCount: 1
app:
  greeting: Welcome
  logLevel: debug
YML
for e in prod dev; do
  if [ $e = prod ]; then files='[../../envs/web-prod/values.yaml, ../../envs/web-dev/values.yaml]'; else files='[../../envs/web-dev/values.yaml]'; fi
  cat > apps/web-$e.yaml <<YML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: web-$e
  namespace: argocd
spec:
  project: lab
  source:
    repoURL: http://git.lab:3000/lab/gitops.git
    targetRevision: main
    path: charts/labapp
    helm:
      releaseName: web
      valueFiles: $files
  destination:
    server: https://kubernetes.default.svc
    namespace: web-$e
  syncPolicy:
    automated: {prune: true, selfHeal: true}
    syncOptions: [CreateNamespace=true]
YML
done
python3 - <<'PY'
p = "apps/project-lab.yaml"; s = open(p).read()
a = "    - {server: https://kubernetes.default.svc, namespace: shop}\n"
s = s.replace(a, a + "".join("    - {server: https://kubernetes.default.svc, namespace: web-%s}\n" % e for e in ("prod", "dev")), 1)
open(p, "w").write(s)
PY
SNIP
argo_refresh lab-apps
for a in web-prod web-dev; do retry 240 argo_app_ok "$a" || die "$a never synced"; done
