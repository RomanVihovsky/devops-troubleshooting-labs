# scraper: "pods is forbidden"
**INC-2801** · P3 · Reporter: monitoring team

The `scraper` (namespace `monitor`) lists the pods of its own namespace through the API and logs
`pods is forbidden: User "system:serviceaccount:monitor:scraper" cannot list resource "pods" in API group
"" in the namespace "monitor"`. The RBAC was applied (`workspace/A01/rbac.yaml`). Least privilege, please.

**Test**: the SA `monitor/scraper` can list pods in `monitor`, and nothing broader (no pods in other
namespaces, no delete, no secrets).
