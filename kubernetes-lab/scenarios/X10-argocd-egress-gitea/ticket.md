# Argo CD can't reach Git since the egress hardening
**INC-2583** · P1 · Reporter: platform team

Security added an egress policy for Argo CD's repo-server (`argocd/repo-server-egress`, `workspace/X10/policy.yaml`):
"DNS only, add what it really needs". Since the next refresh every app shows *ComparisonError ... dial tcp
192.168.56.20:3000: i/o timeout* and nothing deploys. Give the repo-server exactly what it needs: DNS and the Git
server (Gitea, `192.168.56.20:3000`). Egress hardening stays.

**Test**: after a hard refresh, `lab-apps`, `demo` and `shop` are Synced + Healthy with no ComparisonError; an Egress
NetworkPolicy still selects the repo-server pods, and none of them allows all egress (no rule without `to`, no
`0.0.0.0/0`).
