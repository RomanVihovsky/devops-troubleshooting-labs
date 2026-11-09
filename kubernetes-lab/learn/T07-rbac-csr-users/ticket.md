# T07 · RBAC + CSR users: a user certificate, a group binding, a ServiceAccount token
**Learn** · how Kubernetes knows who you are (it doesn't store users) and what you may do · ~40 min

Jane joins the team `t07-devs`: she may **read pods and their logs in namespace `t07` - nothing else**.
The CI system needs to **manage Deployments in `t07`** with a ServiceAccount token. Work in
`workspace/T07/`.

1. **Jane's certificate**: a private key and a CSR with `CN=jane` and `O=t07-devs` (openssl). Submit it as
   a CertificateSigningRequest named **`t07-jane`** (signer `kubernetes.io/kube-apiserver-client`, one day),
   approve it, and fetch the signed certificate.
2. **Her kubeconfig** `workspace/T07/jane.kubeconfig`: the lab API `https://192.168.56.20:6443`, the
   cluster CA, her cert + key embedded. `kubectl --kubeconfig jane.kubeconfig auth whoami`.
3. **RBAC for the team**: a Role in `t07` (pods: get, list, watch; pods/log: get) bound to the **group**
   `t07-devs` - not to jane.
4. **CI**: a ServiceAccount `ci` in `t07`, allowed to get/list/watch/create/update/patch Deployments there,
   and a token for it in `workspace/T07/ci.token` (`kubectl create token`).

**Test**: CSR t07-jane is approved; `jane.kubeconfig` authenticates as jane (group t07-devs) and may list
pods and read logs in t07 but not delete pods, read secrets or touch other namespaces; the binding names the
group; `ci.token` authenticates as `system:serviceaccount:t07:ci`, which can create Deployments in t07 only.
