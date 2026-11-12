# W12 - a PodDisruptionBudget that allows nothing

**Root cause**: `minAvailable: 3` for a 3-replica Deployment: `disruptionsAllowed` is always 0. `kubectl drain`
uses the **Eviction API**, which honours PDBs, so every eviction got 429 and drain retried forever. The
attempt also cordoned `k8s-w1`.

**Diagnosis**
```
kubectl -n ha get pdb ha-api                      # MIN AVAILABLE 3, ALLOWED DISRUPTIONS 0
kubectl get node k8s-w1                           # SchedulingDisabled
```

**Fix**: a budget that protects *and* allows maintenance: `minAvailable: 2` (or `maxUnavailable: 1`). Then drain;
the evicted pod waits for the node (required anti-affinity: one per node) until `kubectl uncordon k8s-w1`.

**Interview notes**
- PDBs limit **voluntary** disruptions (drain, cluster-autoscaler scale-down, `kubectl evict`), not node
  crashes or `kubectl delete pod`.
- `maxUnavailable` scales with the replica count. `minAvailable: <replicas>` is the classic "the upgrade is
  stuck at node 1 of 20" incident (managed node-group upgrades eventually force-delete instead).
- Single-replica apps with `minAvailable: 1` block drains too. Use `unhealthyPodEvictionPolicy: AlwaysAllow`
  so broken pods don't block, and run 2+ replicas for anything with a PDB.
