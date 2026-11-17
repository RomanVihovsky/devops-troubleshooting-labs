# S05 - minDomains larger than the number of zones

**Root cause**: the constraint says `minDomains: 3` (copied from a 3-zone production cluster). When fewer eligible
domains exist than `minDomains`, the scheduler treats the **global minimum as 0**. With `maxSkew: 1` every zone
may then hold at most 0 + 1 = 1 matching pod: zone-a 1, zone-b 1, and the other replicas stay Pending however
empty the nodes are.

**Diagnosis**
```
kubectl -n search get pods -o wide                     # 2 Running (one per zone), 2 Pending
kubectl -n search describe pod <pending>               # ... didn't match pod topology spread constraints
kubectl get nodes -L topology.kubernetes.io/zone       # only zone-a and zone-b
```

**Fix**: remove `minDomains` (or set it to 2). With `maxSkew: 1` the 4 replicas land 2 + 2. Switching to
`whenUnsatisfiable: ScheduleAnyway` would also schedule them, but loses the guarantee the team asked for.

During the rollout the constraint also counts the **old** ReplicaSet's pods (same `app` label), so the new pods
can land 3 + 1 once the old ones are gone. `matchLabelKeys: [pod-template-hash]` makes each revision spread on
its own - the recommended setting for Deployments.

**Interview notes**
- `minDomains` exists for autoscaled clusters: it forces pods into Pending so the cluster autoscaler adds a node
  in a new zone. Without an autoscaler it just blocks.
- Which nodes count as domains: `nodeAffinityPolicy: Honor` (default) and `nodeTaintsPolicy: Ignore` (default) -
  a tainted node still counts unless you set `Honor` (S04).
- Spread is only enforced at scheduling time; the descheduler rebalances later.
