# B03 - four gates in front of a new namespace

1. **RBAC**: the RoleBinding names group `payment-devs`; tina's certificate says `O=payments-devs`. Group names are
   free text - a typo grants nothing. `kubectl auth can-i --list --as tina --as-group payments-devs -n payments-team`.
2. **ResourceQuota** on `requests.cpu/memory` and `limits.memory`: every pod must declare them, or the ReplicaSet's
   pod creation is *forbidden: failed quota: ... must specify ...* (R10). A LimitRange with defaults is the
   platform-side alternative.
3. **Pod Security `restricted`**: runAsNonRoot, `seccompProfile: RuntimeDefault`, `allowPrivilegeEscalation: false`,
   `capabilities.drop: [ALL]` (A04). The FailedCreate event lists exactly what's missing.
4. **default-deny (Ingress + Egress)**: DNS to kube-dns and payments-api -> ledger must be allowed explicitly (both the
   egress side and the ingress side).

**Interview notes**
- The errors arrive one gate at a time: RBAC at `kubectl apply`, quota and PSA as ReplicaSet events (pods never
  exist), NetworkPolicy only at runtime. `kubectl describe rs` is the place most people forget.
- Namespace-as-a-service usually ships LimitRange defaults and a DNS-allow policy with the baseline - exactly to avoid
  this ticket.
