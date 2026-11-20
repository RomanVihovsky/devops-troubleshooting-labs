# D12: Argo CD (prune: true) deleted the PVC after a commit disabled persistence; the Retain PV is Released
kx get storageclass nfs -o json | jq '{apiVersion, kind, metadata: {name: "nfs-retain"}, provisioner, parameters,
  reclaimPolicy: "Retain", volumeBindingMode, mountOptions, allowVolumeExpansion} | with_entries(select(.value != null))' | ka -f -
kns notes
gitops_commit "notes: Argo CD app with persistent storage" dev-alice <<'SNIP'
mkdir -p envs/notes
cat > envs/notes/values.yaml <<'YML'
fullnameOverride: notes
podSecurityContext:
  runAsNonRoot: true
  runAsUser: 10001
  runAsGroup: 10001          # NFS (--manage-gids): the group must be the primary one
  fsGroup: 10001
  seccompProfile: {type: RuntimeDefault}
persistence:
  enabled: true
  storageClass: nfs-retain
  size: 1Gi
YML
cat > apps/notes.yaml <<'YML'
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: notes
  namespace: argocd
spec:
  project: lab
  source:
    repoURL: http://git.lab:3000/lab/gitops.git
    targetRevision: main
    path: charts/labapp
    helm:
      releaseName: notes
      valueFiles: [../../envs/notes/values.yaml]
  destination:
    server: https://kubernetes.default.svc
    namespace: notes
  syncPolicy:
    automated: {prune: true, selfHeal: true}
YML
python3 - <<'PY'
p = "apps/project-lab.yaml"; s = open(p).read()
a = "    - {server: https://kubernetes.default.svc, namespace: shop}\n"
s = s.replace(a, a + "    - {server: https://kubernetes.default.svc, namespace: notes}\n", 1)
open(p, "w").write(s)
PY
SNIP
argo_refresh lab-apps
retry 240 argo_app_ok notes || die "notes never synced"
retry 120 deploy_ready notes notes || die "notes never became Ready"
v="note-$(openssl rand -hex 6)"; remember d12_value "$v"
kx -n notes exec deploy/notes -- labapp get -X PUT -d "$v" http://localhost:8080/kv/meeting-2026-11 >/dev/null
remember d12_pv "$(kx -n notes get pvc notes -o jsonpath='{.spec.volumeName}')"
gitops_commit "notes: drop the PVC (state lives in Redis now)" dev-carol <<'SNIP'
sed -i 's/^  enabled: true$/  enabled: false/' envs/notes/values.yaml
SNIP
argo_refresh notes
released() { [ "$(kx get pv "$(recall d12_pv)" -o jsonpath='{.status.phase}' 2>/dev/null)" = Released ]; }
retry 240 released || die "the PVC was not pruned"
empty() { ! kx -n notes exec deploy/notes -- labapp get -q http://localhost:8080/kv/meeting-2026-11 >/dev/null 2>&1; }
retry 180 empty || die "notes still serves the data"
