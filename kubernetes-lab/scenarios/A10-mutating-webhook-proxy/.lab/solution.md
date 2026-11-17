# A10 - a mutating webhook changes what you deployed

**Root cause**: `egress-guard` (MutatingWebhookConfiguration, namespaces labelled `egress=guarded`) appends
`HTTPS_PROXY`/`HTTP_PROXY` to every container of every new pod. With a proxy set, HTTP clients send **every**
request to it unless the destination is listed in `NO_PROXY` - so wallet's in-cluster call to
`ledger-api.wallet.svc` goes to `egress-proxy:3128`, fails, `/health` (which checks dependencies) fails, and the
kubelet restarts the container. Old pods were created before the webhook and are untouched.

**Diagnosis**
```
kubectl -n wallet get pods                                         # new pods restarting
kubectl -n wallet get pod <new> -o jsonpath='{.spec.containers[0].env}' | jq   # HTTP(S)_PROXY you never wrote
kubectl get mutatingwebhookconfigurations egress-guard -o yaml     # namespaceSelector egress=guarded
kubectl -n security-system get deploy egress-guard -o yaml         # WEBHOOK_PATCH
kubectl -n wallet logs <new> | grep -i upstream
```

**Fix**: inject `NO_PROXY` with the proxy - in the webhook's patch, so every guarded team is fixed:
`NO_PROXY=.svc,.cluster.local,10.96.0.0/12,localhost` (add the pod CIDR if pods call pod IPs). A team-local
alternative is `NO_PROXY` in wallet's own env. Then roll wallet out again.

**Interview notes**
- "My manifest says X, the pod says Y" -> mutating admission (webhooks, LimitRange defaults, PSA doesn't mutate,
  service meshes inject sidecars). Compare the Deployment template with the Pod.
- JSONPatch `add` on an existing path **replaces** it (`/env` would wipe the app's variables); `/env/-` appends
  but fails when the container has no `env` at all.
- `NO_PROXY` syntax differs between clients (Go accepts CIDRs, curl and Python only suffixes) - list both.
- Liveness probes that check dependencies turn a dependency outage into a restart storm (anti-pattern).
