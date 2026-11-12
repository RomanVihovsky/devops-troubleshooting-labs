# D08: ledger installed by helm, adopted by an Argo CD app (same release name); 1.5 (exits at start) goes out
# through Git; on-call's helm rollback is reverted by self-heal
kns ledger
helm install ledger "$LAB_DIR/charts/labapp" -n ledger --set fullnameOverride=ledger --wait --timeout 3m >/dev/null
gitops_commit "ledger: managed by Argo CD from now on (adopts the helm release)" <<'SNIP'
mkdir -p envs/ledger
cat > envs/ledger/values.yaml <<'YML'
# ledger: adopted from its helm release (same release name, same objects)
fullnameOverride: ledger
YML
cat > apps/ledger.yaml <<'YML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ledger
  namespace: argocd
spec:
  project: lab
  source:
    repoURL: http://git.lab:3000/lab/gitops.git
    targetRevision: main
    path: charts/labapp
    helm:
      releaseName: ledger
      valueFiles: [../../envs/ledger/values.yaml]
  destination:
    server: https://kubernetes.default.svc
    namespace: ledger
  syncPolicy:
    automated: {prune: true, selfHeal: true}
YML
python3 - <<'PY'
p = "apps/project-lab.yaml"; s = open(p).read()
a = "    - {server: https://kubernetes.default.svc, namespace: shop}\n"
s = s.replace(a, a + "    - {server: https://kubernetes.default.svc, namespace: ledger}\n", 1)
open(p, "w").write(s)
PY
SNIP
argo_refresh lab-apps
retry 240 argo_app_ok ledger || die "ledger never synced"
gitops_commit "ledger 1.5: server-side sessions (CHG-881)" <<'SNIP'
printf 'image:\n  tag: "1.5"\n' >> envs/ledger/values.yaml
SNIP
argo_refresh ledger
crashing() { crashlooping ledger app.kubernetes.io/instance=ledger; }
retry 240 crashing || die "ledger 1.5 never crashed"
image() { kx -n ledger get deploy ledger -o jsonpath='{.spec.template.spec.containers[0].image}'; }
# on-call's rollback to revision 1 (the 1.4 install); Argo CD's apply owns the fields, hence the conflicts
helm rollback ledger 1 -n ledger --force-conflicts >/dev/null 2>&1 || helm rollback ledger 1 -n ledger --force-replace >/dev/null
rolled() { image | grep -q ':1.4$'; }
back() { image | grep -q ':1.5$'; }
retry 60 rolled || die "helm rollback did not take"
retry 180 back || die "self-heal did not bring 1.5 back"
