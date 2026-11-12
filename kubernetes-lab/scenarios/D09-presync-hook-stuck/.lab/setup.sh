# D09: billing's migration is a PreSync hook (helm pre-install/pre-upgrade) that needs Secret db-creds, which
# the chart's SealedSecret only creates in the Sync phase
kns billing
# the platform team's chart release of the week: annotations for the settings ConfigMap (hooks, waves)
gitops_commit "labapp chart: config.annotations for the settings ConfigMap" "dev-platform" <<'SNIP'
f=charts/labapp/templates/configmap.yaml
awk '{ print } !done && /include "labapp.labels"/ { print "  {{- with .Values.config.annotations }}"; print "  annotations:"; print "    {{- toYaml . | nindent 4 }}"; print "  {{- end }}"; done = 1 }' "$f" > "$f.new" && mv "$f.new" "$f"
sed -i '0,/^config:$/s//config:\n  annotations: {}                     # on the settings ConfigMap, e.g. Argo CD hook\/sync-wave/' charts/labapp/values.yaml
grep -q 'Values.config.annotations' "$f" && grep -q '^  annotations: {}  ' charts/labapp/values.yaml
SNIP
pw=$(rand)
sealed=$(printf %s "$pw" | "$BIN_DIR/kubeseal" --raw --cert "$SEALED_CERT" --scope strict --namespace billing --name db-creds --from-file=/dev/stdin)
remember db_password "$pw"
gitops_commit "billing: new service (schema migration before every release)" <<SNIP
mkdir -p envs/billing
cat > envs/billing/values.yaml <<'YML'
# billing: the migration runs BEFORE the new version (PreSync); it needs the DB password
fullnameOverride: billing
serviceAccount:
  create: false          # the namespace's default ServiceAccount (exists before any phase)
secrets:
  source: sealedSecret
  name: db-creds
  env:
    DATABASE_PASSWORD: password
  sealedSecret:
    scope: strict
    encryptedData:
      password: $sealed
migrations:
  enabled: true
  hook: pre-install,pre-upgrade
YML
cat > apps/billing.yaml <<'YML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: billing
  namespace: argocd
spec:
  project: lab
  source:
    repoURL: http://git.lab:3000/lab/gitops.git
    targetRevision: main
    path: charts/labapp
    helm:
      releaseName: billing
      valueFiles: [../../envs/billing/values.yaml]
  destination:
    server: https://kubernetes.default.svc
    namespace: billing
  syncPolicy:
    automated: {prune: true, selfHeal: true}
YML
python3 - <<'PY'
p = "apps/project-lab.yaml"; s = open(p).read()
a = "    - {server: https://kubernetes.default.svc, namespace: shop}\n"
s = s.replace(a, a + "    - {server: https://kubernetes.default.svc, namespace: billing}\n", 1)
open(p, "w").write(s)
PY
SNIP
argo_refresh lab-apps
waiting() { kx -n argocd get application billing -o json 2>/dev/null | jq -e '.status.operationState.phase == "Running"
              and (.status.operationState.message // "" | test("waiting for completion of hook"))' >/dev/null; }
retry 240 waiting || die "billing's sync is not waiting for the hook"
stuck() { kx -n billing get pods -l app.kubernetes.io/name=labapp-migrate -o json | jq -e '[.items[].status.containerStatuses[]?.state.waiting.reason] | index("CreateContainerConfigError")' >/dev/null; }
retry 120 stuck || die "the migration pod is not stuck on its Secret"
