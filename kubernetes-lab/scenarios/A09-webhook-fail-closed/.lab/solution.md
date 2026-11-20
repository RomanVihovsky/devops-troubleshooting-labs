# A09 - a fail-closed webhook without endpoints blocks a namespace

**Root cause**: `pod-policy` covers every create/update in namespaces labelled `policy=enforced` with
`failurePolicy: Fail`. Its new readiness probe uses `httpGet` without `scheme`, i.e. **HTTP**, against a server
that only speaks TLS. The probe fails, the pod never becomes Ready, the Service has no ready endpoints, and the
API server can't call the webhook - so with `Fail` it rejects everything in `orders`.

**Diagnosis**
```
kubectl -n orders create configmap t --dry-run=server            # failed calling webhook ... no endpoints
kubectl get validatingwebhookconfiguration pod-policy -o yaml      # rules, namespaceSelector, failurePolicy
kubectl -n policy-system get pods,endpointslices
kubectl -n policy-system describe pod -l app=pod-policy            # Readiness probe failed ... (HTTP to TLS)
```

**Fix**: `readinessProbe.httpGet.scheme: HTTPS` (the kubelet skips certificate verification for probes).
Once the pod is Ready, the API server reaches the webhook and `orders` works - with the policy still enforced.

**Interview notes**
- Blast radius: a fail-closed webhook that matches **all** namespaces can block the webhook's own namespace
  (deadlock: its pods can't be recreated) or `kube-system`. Always exclude them with a `namespaceSelector`.
- `failurePolicy: Ignore` would "fix" the outage by silently dropping the policy - a security decision, not an
  ops fix. `timeoutSeconds` (default 10, max 30) bounds how long every request waits.
- Emergency exit if the webhook can't be fixed: delete or patch the `*WebhookConfiguration` (cluster-admin),
  then restore it.
- `--dry-run=server` runs admission webhooks (with `sideEffects: None`), a safe way to test them.
