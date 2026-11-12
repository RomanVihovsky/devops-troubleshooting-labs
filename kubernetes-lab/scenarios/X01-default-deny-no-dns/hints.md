## Hint 1
`kubectl -n zt exec deploy/client -- labapp get http://localhost:8080/upstream` - read the error. Is it a refused
connection, a timeout, or a name that doesn't resolve?

## Hint 2
To call `backend.zt.svc` the pod first asks DNS: CoreDNS in `kube-system`, UDP and TCP port 53. With default-deny
**egress**, that is blocked too.

## Hint 3
Add an egress rule for DNS: `to: [{namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: kube-system}},
podSelector: {matchLabels: {k8s-app: kube-dns}}}]`, `ports: [{protocol: UDP, port: 53}, {protocol: TCP, port: 53}]`.
