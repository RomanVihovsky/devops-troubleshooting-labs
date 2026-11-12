## Hint 1
`argocd app get demo --hard-refresh` and `kubectl -n argocd get networkpolicy`. Which pods does
`repo-server-egress` select, and where may they connect?

## Hint 2
The repo-server clones Git over HTTP from Gitea on `k8s-gw` - outside the cluster: an `ipBlock`. Which address and
port does it dial (the error says it)?

## Hint 3
Add to `repo-server-egress`: `- to: [{ipBlock: {cidr: 192.168.56.20/32}}]` with `ports: [{protocol: TCP, port: 3000}]`,
apply, then `argocd app get demo --hard-refresh`.
