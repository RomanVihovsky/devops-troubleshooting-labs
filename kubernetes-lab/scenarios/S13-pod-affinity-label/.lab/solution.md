# S13 - pod affinity to a label nobody has

**Root cause**: `session-api` requires (`requiredDuringScheduling...`) a pod with `app: cache` on the same node
(`topologyKey: kubernetes.io/hostname`). The cache's pods are labelled `app: redis-cache`. No node satisfied the
rule, so the pods stayed Pending.

**Diagnosis**
```
kubectl -n sessions describe pod -l app=session-api | grep -A3 Events   # didn't match pod affinity rules
kubectl -n sessions get pods --show-labels
kubectl -n sessions get deploy session-api -o jsonpath='{.spec.template.spec.affinity}'; echo
```

**Fix**: `matchLabels: {app: redis-cache}`.

**Interview notes**
- Pod (anti-)affinity: "place relative to **pods** with label X within topology Y". Node affinity: "place on
  **nodes** with label X". The selector matches pods in the pod's namespace by default.
- Required pod affinity to a single cache pod ties both to one node. Losing that node (or the cache moving)
  takes both down. `preferred` is often the better choice.
- Pod affinity is expensive for the scheduler in large clusters. topologySpreadConstraints cover the "spread"
  cases more cheaply.
