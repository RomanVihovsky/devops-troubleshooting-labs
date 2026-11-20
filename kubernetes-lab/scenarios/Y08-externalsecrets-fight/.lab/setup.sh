# Y08: two ExternalSecrets with creationPolicy Merge write key apikey of the same hand-made Secret -> flip-flop
kns partners
old="pk_legacy_$(rand)"; new="pk_live_$(rand)"; remember y08_old "$old"; remember y08_new "$new"
bx kv put -mount=secret partners/legacy apikey="$old" >/dev/null
bx kv put -mount=secret partners/api apikey="$new" >/dev/null
printf 'path "secret/data/partners/*" { capabilities = ["read"] }\n' | bx policy write partners-read - >/dev/null
bx write auth/kubernetes/role/partners bound_service_account_names=eso bound_service_account_namespaces=partners \
  token_policies=partners-read audience=openbao token_ttl=1h >/dev/null
kx -n partners create configmap lab-ca --from-file=ca.crt="$CA_DIR/ca.crt" --dry-run=client -o yaml | ka -f -
kx -n partners create secret generic api-key --from-literal=apikey=set-me --dry-run=client -o yaml | ka -f -
gitops_commit "partners: API key from OpenBao (legacy path + new path during the migration)" dev-dana <<'SNIP'
mkdir -p envs/partners
cat > envs/partners/store.yaml <<'YML'
apiVersion: v1
kind: ServiceAccount
metadata: {name: eso, namespace: partners}
---
apiVersion: external-secrets.io/v1
kind: SecretStore
metadata: {name: openbao, namespace: partners}
spec:
  provider:
    vault:
      server: https://bao.lab:8200
      path: secret
      version: v2
      caProvider: {type: ConfigMap, name: lab-ca, key: ca.crt}
      auth:
        kubernetes:
          mountPath: kubernetes
          role: partners
          serviceAccountRef: {name: eso, audiences: [openbao]}
YML
cat > envs/partners/api-key-legacy.yaml <<'YML'
# the original integration (2024) - keeps api-key in sync with the legacy path
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata: {name: api-key-legacy, namespace: partners}
spec:
  refreshInterval: 20s
  secretStoreRef: {kind: SecretStore, name: openbao}
  target: {name: api-key, creationPolicy: Merge}
  data:
    - secretKey: apikey
      remoteRef: {key: partners/legacy, property: apikey}
YML
cat > envs/partners/api-key.yaml <<'YML'
# PARTNER-212: the key moved to partners/api
apiVersion: external-secrets.io/v1
kind: ExternalSecret
metadata: {name: api-key, namespace: partners}
spec:
  refreshInterval: 30s
  secretStoreRef: {kind: SecretStore, name: openbao}
  target: {name: api-key, creationPolicy: Merge}
  data:
    - secretKey: apikey
      remoteRef: {key: partners/api, property: apikey}
YML
cat > apps/partners.yaml <<'YML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: partners
  namespace: argocd
spec:
  project: lab
  source:
    repoURL: http://git.lab:3000/lab/gitops.git
    targetRevision: main
    path: envs/partners
  destination:
    server: https://kubernetes.default.svc
    namespace: partners
  syncPolicy:
    automated: {prune: true, selfHeal: true}
YML
python3 - <<'PY'
p = "apps/project-lab.yaml"; s = open(p).read()
a = "    - {server: https://kubernetes.default.svc, namespace: shop}\n"
s = s.replace(a, a + "    - {server: https://kubernetes.default.svc, namespace: partners}\n", 1)
open(p, "w").write(s)
PY
SNIP
argo_refresh lab-apps
retry 240 argo_app_ok partners || die "partners never synced"
val() { kx -n partners get secret api-key -o jsonpath='{.data.apikey}' 2>/dev/null | base64 -d; }
seen=""
flipped() { local v; v=$(val); case $v in "$old") seen="${seen}o" ;; "$new") seen="${seen}n" ;; esac; [[ $seen == *o*n* || $seen == *n*o* ]]; }
retry 180 flipped || die "api-key never flipped (seen: $seen)"
