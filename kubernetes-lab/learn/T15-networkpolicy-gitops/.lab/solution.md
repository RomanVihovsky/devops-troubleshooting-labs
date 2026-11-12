# T15 - solution and takeaways

shop: `default-deny` (all pods, Ingress + Egress) + `allow-dns`, then one policy per component:
- frontend: ingress from namespace `traefik` on 8080; egress to `api` on 8080;
- api: ingress from `frontend` on 8080; egress to `postgres` 5432 and `redis` 6379;
- postgres / redis: ingress from `api` on their port.

external-secrets and argocd: `podSelector: {}`, `policyTypes: [Egress]`, allowing:
- DNS (kube-system/kube-dns 53 UDP+TCP);
- `ipBlock 192.168.56.21/32` port **6443** - the API server *after* kube-proxy's DNAT;
- OpenBao `192.168.56.20/32:8200` (ESO), or Gitea `192.168.56.20/32:3000` + `podSelector: {}` (Argo CD's
  own components talk to each other: redis, repo-server).

**Takeaways**
- The first casualty of default deny is DNS; the second is everything that talks to the API server.
- NetworkPolicy sees pod/endpoint IPs, not Service IPs: for in-cluster Services that is invisible (you
  select pods), for the API server (an endpoint outside the pod network) you need its real IP and port. Many
  CNIs behave like this; Cilium has `toEntities: [kube-apiserver]`.
- A flow needs egress on the client and ingress on the server. Policies only add allowances: there's no
  "deny" in Kubernetes NetworkPolicy (Calico/Cilium have their own CRDs for that).
- Lock down the controllers that hold credentials (ESO, Argo CD) - they're the juiciest pods in the
  cluster (X09, X10).
