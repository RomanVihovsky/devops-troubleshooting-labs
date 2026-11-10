# N05 - short names resolve in the pod's own namespace

**Root cause**: `http://api` → `api.storefront.svc.cluster.local` (first search domain) - no such Service.
The API lives in `inventory-api`.

**Fix**: `http://api.inventory-api` (or `api.inventory-api.svc.cluster.local`).

**Interview notes**
- Pod resolv.conf: `search <ns>.svc.cluster.local svc.cluster.local cluster.local` + `ndots:5` - short
  names are tried with each suffix (N08 is the cost of that).
- Cross-namespace calls should use `<svc>.<ns>` - explicit, and NetworkPolicies then need a
  namespaceSelector too (X domain).
