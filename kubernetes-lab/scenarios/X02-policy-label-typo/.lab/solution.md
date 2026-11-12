# X02 - a policy that selects nobody

**Root cause**: `backend-allow` allows ingress from `podSelector: {app: frontned}`. No pod has that label. Since
the policy selects `backend` for Ingress, everything not explicitly allowed is denied, so the frontend was
blocked too. The policy is valid YAML and the API accepts it; nothing warns about a selector that matches
nothing.

**Diagnosis**
```
kubectl -n shopx describe networkpolicy backend-allow       # "From: PodSelector: app=frontned"
kubectl -n shopx get pods -l app=frontned                   # No resources found
kubectl -n shopx get pods --show-labels
```

**Fix**: `app: frontend`.

**Interview notes**
- Test policies from the client's point of view: a throwaway pod **with the client's labels** (`kubectl run
  --labels`), and keep a "should be blocked" probe too.
- `podSelector` in `from` = pods in the **policy's** namespace; add `namespaceSelector` for other namespaces
  (X03, X05).
- Policy linting (e.g. `kubectl np-viewer`, Cilium's editor, `netassert`) catches selectors that match nothing.
