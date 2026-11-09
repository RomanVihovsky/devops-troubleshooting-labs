## Hint 1
Default deny breaks DNS first: every pod needs egress to `kube-system` pods `k8s-app: kube-dns` on 53/UDP
and 53/TCP. A flow needs **both** sides: egress on the client's policy *and* ingress on the server's. Policies
are additive: any policy that allows a packet wins.

## Hint 2
```yaml
ingress: [{from: [{namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: traefik}}}],
           ports: [{port: 8080}]}]
egress:  [{to: [{podSelector: {matchLabels: {app.kubernetes.io/name: api}}}], ports: [{port: 8080}]}]
```
Selectors without a namespaceSelector stay in the policy's own namespace.

## Hint 3
Pods reach the API at `kubernetes.default.svc` = 10.96.0.1:443, but kube-proxy DNATs that to the real
endpoint **before** Calico evaluates the policy: allow `ipBlock: 192.168.56.21/32` port **6443**
(`kubectl get endpointslices -n default`), not 10.96.0.1:443. OpenBao and Gitea run on the host network of
k8s-gw: `ipBlock: 192.168.56.20/32` with their ports.
