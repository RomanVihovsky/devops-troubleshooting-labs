# T07 - solution and takeaways

```
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -subj "/CN=jane/O=t07-devs" -out jane.csr
# CertificateSigningRequest t07-jane: request=$(base64 -w0 jane.csr),
#   signerName kubernetes.io/kube-apiserver-client, usages [client auth], expirationSeconds 86400
kubectl certificate approve t07-jane
kubectl get csr t07-jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt
kubectl --kubeconfig jane.kubeconfig config set-cluster/set-credentials/set-context/use-context ...
kubectl -n t07 create role pod-reader --verb=get,list,watch --resource=pods   (+ pods/log: get)
kubectl -n t07 create rolebinding pod-readers --role=pod-reader --group=t07-devs
kubectl -n t07 create serviceaccount ci
kubectl -n t07 create role deployer --verb=get,list,watch,create,update,patch --resource=deployments
kubectl -n t07 create rolebinding ci --role=deployer --serviceaccount=t07:ci
kubectl -n t07 create token ci --duration=24h > ci.token
```

**Takeaways**
- Kubernetes has no user database. A client certificate **is** the identity: CN = user, O = groups,
  signed by the cluster CA. It cannot be revoked - only expire (hence short `expirationSeconds`), or lose
  its permissions (bind groups, not users).
- RBAC is additive (no deny rules): Role/ClusterRole = what, RoleBinding/ClusterRoleBinding = who and where.
  A ClusterRole bound with a RoleBinding is limited to that namespace.
- `pods/log`, `pods/exec`, `deployments/scale` are subresources with their own rules - "can list pods but
  not read logs" is a classic ticket (A domain).
- ServiceAccount tokens: `kubectl create token` gives a short-lived, audience-bound JWT (TokenRequest API);
  the old long-lived token Secrets are no longer created automatically.
- `kubectl auth can-i --as=<user> --as-group=<group>` and `kubectl auth whoami` are the debugging tools.
