openssl genrsa -out jane.key 2048 2>/dev/null
openssl req -new -key jane.key -subj "/CN=jane/O=t07-devs" -out jane.csr
cat > csr.yaml <<YML
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata: {name: t07-jane}
spec:
  request: $(base64 -w0 jane.csr)
  signerName: kubernetes.io/kube-apiserver-client
  usages: [client auth]
  expirationSeconds: 86400
YML
kx apply -f csr.yaml >/dev/null
kx certificate approve t07-jane >/dev/null
issued() { [ -n "$(kx get csr t07-jane -o jsonpath='{.status.certificate}')" ]; }
retry 30 issued
kx get csr t07-jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt
kx config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64 -d > ca.crt
K="kubectl --kubeconfig jane.kubeconfig"
$K config set-cluster lab --server=https://192.168.56.20:6443 --certificate-authority=ca.crt --embed-certs >/dev/null
$K config set-credentials jane --client-certificate=jane.crt --client-key=jane.key --embed-certs >/dev/null
$K config set-context jane --cluster=lab --user=jane >/dev/null
$K config use-context jane >/dev/null
kx -n t07 apply -f - >/dev/null <<'YML'
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: pod-reader, namespace: t07}
rules:
  - {apiGroups: [""], resources: [pods], verbs: [get, list, watch]}
  - {apiGroups: [""], resources: [pods/log], verbs: [get]}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: pod-readers, namespace: t07}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: pod-reader}
subjects: [{apiGroup: rbac.authorization.k8s.io, kind: Group, name: t07-devs}]
---
apiVersion: v1
kind: ServiceAccount
metadata: {name: ci, namespace: t07}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata: {name: deployer, namespace: t07}
rules:
  - {apiGroups: [apps], resources: [deployments], verbs: [get, list, watch, create, update, patch]}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata: {name: ci, namespace: t07}
roleRef: {apiGroup: rbac.authorization.k8s.io, kind: Role, name: deployer}
subjects: [{kind: ServiceAccount, name: ci, namespace: t07}]
YML
kx -n t07 create token ci --duration=24h > ci.token
