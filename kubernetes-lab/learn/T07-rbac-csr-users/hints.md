## Hint 1
```
openssl genrsa -out jane.key 2048
openssl req -new -key jane.key -subj "/CN=jane/O=t07-devs" -out jane.csr
```
CSR object: `spec.request: <base64 -w0 jane.csr>`, `signerName: kubernetes.io/kube-apiserver-client`,
`usages: [client auth]`, `expirationSeconds: 86400`. `kubectl certificate approve t07-jane`;
`kubectl get csr t07-jane -o jsonpath='{.status.certificate}' | base64 -d > jane.crt`.

## Hint 2
The CA: `kubectl config view --raw -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | base64
-d > ca.crt`. Then `kubectl --kubeconfig jane.kubeconfig config set-cluster lab --server=... 
--certificate-authority=ca.crt --embed-certs`, `set-credentials jane --client-certificate=jane.crt
--client-key=jane.key --embed-certs`, `set-context jane --cluster=lab --user=jane`, `use-context jane`.

## Hint 3
`kubectl -n t07 create role pod-reader --verb=get,list,watch --resource=pods` plus a rule for `pods/log`
(edit it, or a second role); `kubectl -n t07 create rolebinding pod-readers --role=pod-reader
--group=t07-devs`. CI: `create serviceaccount ci`, `create role deployer --verb=... --resource=deployments`,
`create rolebinding ci --role=deployer --serviceaccount=t07:ci`, `kubectl -n t07 create token ci
--duration=24h > ci.token`. Check with `kubectl auth can-i --as=...`.
