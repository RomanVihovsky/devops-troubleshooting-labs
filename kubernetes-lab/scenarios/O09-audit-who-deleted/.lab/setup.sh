# O09: auditing on; several actors touch checkout's ConfigMaps - carol deletes feature-flags with a script (curl)
kns checkout
ka -f feature-flags.yaml
kx -n checkout create configmap checkout-config --from-literal=region=eu --dry-run=client -o yaml | ka -f -
kx -n checkout create configmap old-banner --from-literal=text=winter-sale --dry-run=client -o yaml | ka -f -
ka -f - <<'YML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: config-editor, namespace: checkout}
rules: [{apiGroups: [""], resources: [configmaps], verbs: [get, list, update, patch, delete]}]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: editors, namespace: checkout}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: config-editor}
subjects:
  - {kind: User, name: bob, apiGroup: rbac.authorization.k8s.io}
  - {kind: User, name: carol, apiGroup: rbac.authorization.k8s.io}
YML
audit_enable <<'POL'
apiVersion: audit.k8s.io/v1
kind: Policy
omitStages: [RequestReceived]
rules:
  - {level: None, users: [system:kube-controller-manager, system:kube-scheduler], verbs: [get, list, watch]}
  - {level: Metadata, resources: [{group: "", resources: [secrets, configmaps]}]}
  - {level: None}
POL
for u in bob carol dave; do user_kubeconfig "$u" devs "$STATE_DIR/scenario.o09-$u.kubeconfig"; done
as() { local u=$1; shift; KUBECONFIG="$STATE_DIR/scenario.o09-$u.kubeconfig" kubectl "$@"; }
as bob -n checkout get configmaps >/dev/null
as dave -n checkout delete configmap feature-flags >/dev/null 2>&1 || true      # 403: dave has no access
as bob -n checkout delete configmap old-banner >/dev/null                         # a legitimate cleanup
sleep 3
# carol's script: a raw API call with a custom user agent
srv=$(KUBECONFIG="$STATE_DIR/scenario.o09-carol.kubeconfig" kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}')
t=$(mktemp -d)
KUBECONFIG="$STATE_DIR/scenario.o09-carol.kubeconfig" kubectl config view --minify --raw -o jsonpath='{.users[0].user.client-certificate-data}' | base64 -d > "$t/crt"
KUBECONFIG="$STATE_DIR/scenario.o09-carol.kubeconfig" kubectl config view --minify --raw -o jsonpath='{.users[0].user.client-key-data}' | base64 -d > "$t/key"
KUBECONFIG="$STATE_DIR/scenario.o09-carol.kubeconfig" kubectl config view --minify --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > "$t/ca"
curl -fsS -o /dev/null --cacert "$t/ca" --cert "$t/crt" --key "$t/key" -A "cleanup-cron/1.2 (python-requests)" \
  -X DELETE "$srv/api/v1/namespaces/checkout/configmaps/feature-flags"
rm -rf "$t"
remember o09_when "$(date -u +%s)"
as bob -n checkout patch configmap checkout-config --type merge -p '{"data":{"region":"eu-west"}}' >/dev/null
logged() { local o; o=$(nx "$CP" 'grep -c "feature-flags" /var/log/kubernetes/audit/audit.log' </dev/null 2>/dev/null) || true; [ "${o:-0}" -ge 2 ]; }
retry 60 logged || die "the delete is not in the audit log"
