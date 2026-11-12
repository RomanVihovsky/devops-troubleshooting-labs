# X10 - egress hardening for Argo CD's repo-server

**Root cause**: `repo-server-egress` selects the repo-server pods and allows only DNS. The repo-server is the
component that clones Git: every refresh dialled `192.168.56.20:3000` (Gitea on `k8s-gw`) and timed out, so all
apps ended in `ComparisonError`. Running workloads were unaffected; only deployments stopped.

**Diagnosis**
```
argocd app get demo --hard-refresh          # ComparisonError ... dial tcp 192.168.56.20:3000: i/o timeout
kubectl -n argocd get networkpolicy
kubectl -n argocd describe networkpolicy repo-server-egress
kubectl -n argocd logs deploy/argocd-repo-server | grep -m3 timeout
```

**Fix**: add `to: [{ipBlock: {cidr: 192.168.56.20/32}}]`, port TCP 3000.

**Interview notes**
- Argo CD's egress needs per component: repo-server → Git (and Helm/OCI registries), application-controller
  → the Kubernetes API of every managed cluster (post-DNAT: `192.168.56.21:6443` here, not `10.96.0.1:443`),
  server → Dex/OIDC, all → redis + DNS. T15 builds the full set.
- Selector choice matters: the policy selects `app.kubernetes.io/component: repo-server`. Labels are API.
- Timeouts (dropped packets) mean a policy or firewall; "connection refused" means the host answered and
  nothing listens.
