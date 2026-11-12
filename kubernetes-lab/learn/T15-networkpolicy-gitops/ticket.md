# T15 · NetworkPolicy for a GitOps stack: default deny, DNS, app flows, ESO and Argo CD egress
**Learn** · zero trust for `shop`, and egress control for the controllers that feed it · ~60 min

Security wants **default deny** in `shop`, and **egress control** for `external-secrets` and `argocd`.
Calico enforces NetworkPolicy here. Starters are in `workspace/T15/`; select pods by
`app.kubernetes.io/name` (frontend, api, postgres, redis). Keep `curl -H 'Host: shop.lab'
http://192.168.56.200/upstream` working after every step.

1. **shop**: apply `shop.yaml` (default deny in and out + DNS). shop.lab breaks - why exactly?
2. Allow only the real flows: Traefik (namespace `traefik`) → frontend:8080 → api:8080 → postgres:5432 and
   redis:6379. Nothing else - e.g. the frontend must not reach the database.
3. **external-secrets**: deny all egress except DNS, OpenBao (`bao.lab` = 192.168.56.20:8200) and the
   Kubernetes API. Prove ESO still works: `kubectl -n shop annotate externalsecret shop-secrets
   force-sync=$(date +%s) --overwrite`. If it breaks: which IP:port does a pod *really* send its API
   traffic to?
4. **argocd**: deny all egress except DNS, traffic inside `argocd`, the Kubernetes API and Gitea (`git.lab` =
   192.168.56.20:3000). Prove it: `argocd app get shop --hard-refresh`.

**Test**: the allowed flows connect and the forbidden ones (frontend→postgres/redis, api→k8s-gw:22,
repo-server→k8s-gw:22) don't; shop.lab works end to end; egress policies cover every pod in
external-secrets and argocd; ESO can still refresh `shop-secrets` and Argo CD can still read Git.
