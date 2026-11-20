# X05 - two `from` items are OR, one item with two selectors is AND

**Root cause**:
```yaml
from:
  - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: monitoring}}   # source 1: ALL pods in monitoring
  - podSelector: {matchLabels: {app: prometheus}}                                 # source 2: app=prometheus in *db*
```
Each list item is its own source; sources are ORed. A lone `podSelector` means "pods in the policy's own
namespace", so the second item even admits any `db` pod that labels itself `app: prometheus`.

**Diagnosis**
```
kubectl -n db describe networkpolicy allow-prometheus     # "From: NamespaceSelector: ...  From: PodSelector: ..."
kubectl -n monitoring run t --rm -it --image=registry.k8s.io/e2e-test-images/agnhost:2.66.0 -- /agnhost connect orders-db.db.svc:5432
```

**Fix**: one item, both selectors (AND):
```yaml
from:
  - namespaceSelector: {matchLabels: {kubernetes.io/metadata.name: monitoring}}
    podSelector: {matchLabels: {app: prometheus}}
```

**Interview notes**
- `kubectl describe networkpolicy` is the quickest way to see how many sources the YAML really has.
- Policies are additive (union of all allows); there's no "deny" rule in the core API - order doesn't matter.
- `kubernetes.io/metadata.name` is set by the API server and can't be forged; custom namespace labels can (X03).
- `ports` use the **pod's** port (8080), not the Service port (5432) - policies act after DNAT (X04).
