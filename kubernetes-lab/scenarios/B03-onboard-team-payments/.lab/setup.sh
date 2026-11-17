# B03: the platform baseline for payments-team with a RoleBinding to "payment-devs" (typo); the team's manifests
# have no resources and no securityContext; default-deny without DNS / intra-namespace allows
kns payments-team
kx label namespace payments-team pod-security.kubernetes.io/enforce=restricted pod-security.kubernetes.io/enforce-version=latest --overwrite >/dev/null
ka -f - <<'YML'
apiVersion: v1
kind: ResourceQuota
metadata: {name: team-quota, namespace: payments-team}
spec:
  hard: {requests.cpu: "1", requests.memory: 1Gi, limits.memory: 2Gi, pods: "10"}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: team-edit, namespace: payments-team}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: ClusterRole, name: edit}
subjects: [{kind: Group, name: payment-devs, apiGroup: rbac.authorization.k8s.io}]
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata: {name: default-deny, namespace: payments-team}
spec:
  podSelector: {}
  policyTypes: [Ingress, Egress]
YML
remember b03_quota "$(kx -n payments-team get resourcequota team-quota -o jsonpath='{.spec}')"
remember b03_deny "$(kx -n payments-team get networkpolicy default-deny -o jsonpath='{.spec}')"
user_kubeconfig tina payments-devs "$STATE_DIR/scenario.b03-tina.kubeconfig"
! KUBECONFIG="$STATE_DIR/scenario.b03-tina.kubeconfig" kubectl -n payments-team auth can-i create deployments >/dev/null 2>&1 || die "tina can already deploy"
ka -f payments.yaml            # "an admin applied it for us": Deployments exist, their pods are rejected
rejected() { local o; o=$(kx -n payments-team get events --field-selector reason=FailedCreate -o jsonpath='{.items[*].message}' 2>/dev/null) || true; grep -qE 'forbidden' <<<"$o"; }
retry 60 rejected || die "the pods were not rejected"
