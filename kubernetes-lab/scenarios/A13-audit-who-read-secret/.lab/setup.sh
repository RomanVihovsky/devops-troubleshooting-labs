# A13: auditing (Secrets at Metadata); the key is read by a CronJob-style pod as ci/reporter and by user bob
kns payments ci partners-int
kx -n payments create secret generic api-key --from-literal=key="pk_live_$(openssl rand -hex 12)" --dry-run=client -o yaml | ka -f -
kx -n payments create secret generic db-creds --from-literal=password="$(openssl rand -hex 12)" --dry-run=client -o yaml | ka -f -
kx -n partners-int create secret generic api-key --from-literal=key="pk_test_$(openssl rand -hex 12)" --dry-run=client -o yaml | ka -f -
ka -f - <<'YML'
apiVersion: v1
kind: ServiceAccount
metadata: {name: reporter, namespace: ci}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: read-api-key, namespace: payments}
rules: [{apiGroups: [""], resources: [secrets], resourceNames: [api-key], verbs: [get]}]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: reporter-reads-api-key, namespace: payments}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: read-api-key}
subjects:
  - {kind: ServiceAccount, name: reporter, namespace: ci}
  - {kind: User, name: bob, apiGroup: rbac.authorization.k8s.io}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: read-secrets, namespace: partners-int}
rules: [{apiGroups: [""], resources: [secrets], verbs: [get, list]}]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: alice-reads, namespace: partners-int}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: read-secrets}
subjects: [{kind: User, name: alice, apiGroup: rbac.authorization.k8s.io}]
YML
audit_enable <<'POL'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages: [RequestReceived]
rules:
  - {level: Metadata, resources: [{group: "", resources: [secrets, configmaps]}]}
  - {level: None}
POL
# the reads: a pod as ci/reporter, user bob from a laptop, and noise from alice in another namespace
pod="nightly-export-$(openssl rand -hex 3)"; remember a13_pod "$pod"
kx -n ci run "$pod" --restart=Never --image=registry.lab:5000/lab/labapp:1.4 --overrides='{"spec":{"serviceAccountName":"reporter"}}' \
  --labels="$LAB_LABEL=$LAB_ID" --command -- labapp read-secret payments/api-key >/dev/null
done_() { [ "$(kx -n ci get pod "$pod" -o jsonpath='{.status.phase}')" = Succeeded ]; }
retry 120 done_ || die "the export pod did not read the secret"
user_kubeconfig bob devs "$STATE_DIR/scenario.a13-bob.kubeconfig"
user_kubeconfig alice devs "$STATE_DIR/scenario.a13-alice.kubeconfig"
KUBECONFIG="$STATE_DIR/scenario.a13-bob.kubeconfig" kubectl -n payments get secret api-key -o yaml >/dev/null
KUBECONFIG="$STATE_DIR/scenario.a13-alice.kubeconfig" kubectl -n partners-int get secret api-key -o yaml >/dev/null
KUBECONFIG="$STATE_DIR/scenario.a13-alice.kubeconfig" kubectl -n partners-int get secrets >/dev/null
logged() { local o; o=$(nx "$CP" 'grep -c "\"name\":\"api-key\"" /var/log/kubernetes/audit/audit.log' </dev/null 2>/dev/null) || true; [ "${o:-0}" -ge 3 ]; }
retry 60 logged || die "the reads are not in the audit log"
