# D04: team-a's project allows "payment" (typo), the app wants "payments"
gitops_commit "onboard team-a: project + payments app (INC-2252)" <<'SNIP'
cat > apps/project-team-a.yaml <<'YML'
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: team-a
  namespace: argocd
spec:
  description: team-a applications
  sourceRepos:
    - http://git.lab:3000/lab/gitops.git
  destinations:
    - {server: https://kubernetes.default.svc, namespace: payment}
  clusterResourceWhitelist:
    - {group: "", kind: Namespace}
YML
cat > apps/payments.yaml <<'YML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: payments
  namespace: argocd
  finalizers: [resources-finalizer.argocd.argoproj.io]
spec:
  project: team-a
  source:
    repoURL: http://git.lab:3000/lab/gitops.git
    targetRevision: main
    path: charts/labapp
    helm:
      releaseName: payments
      valuesObject: {fullnameOverride: payments, app: {name: payments}}
  destination:
    server: https://kubernetes.default.svc
    namespace: payments
  syncPolicy:
    automated: {prune: true, selfHeal: true}
    syncOptions: [CreateNamespace=true]
YML
SNIP
argo_refresh lab-apps
denied() { kx -n argocd get application payments -o jsonpath='{.status.conditions[*].message}' 2>/dev/null | grep -qiE 'allowed destinations|not permitted'; }
retry 180 denied || die "payments never showed the project error"
