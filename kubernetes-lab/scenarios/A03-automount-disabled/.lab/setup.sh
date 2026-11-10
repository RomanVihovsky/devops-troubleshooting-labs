kns janitor
ka -f - <<'YML'
apiVersion: v1
kind: ServiceAccount
metadata: {name: janitor, namespace: janitor}
automountServiceAccountToken: false
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: pod-lister, namespace: janitor}
rules: [{apiGroups: [""], resources: [pods], verbs: [get, list]}]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: janitor, namespace: janitor}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: pod-lister}
subjects: [{kind: ServiceAccount, name: janitor, namespace: janitor}]
YML
kx -n janitor patch sa default -p '{"automountServiceAccountToken": false}' >/dev/null
ka -f janitor.yaml
wait_rollout janitor deploy/janitor
