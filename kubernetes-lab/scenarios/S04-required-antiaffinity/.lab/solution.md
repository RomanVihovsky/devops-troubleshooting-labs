# S04 - hard anti-affinity caps replicas at the node count

**Root cause**: required pod anti-affinity on `kubernetes.io/hostname` allows one gateway pod per node; with
3 schedulable workers the 4th and 5th can't be placed.

**Fix**: soft spreading - `topologySpreadConstraints` with `ScheduleAnyway` (or preferred anti-affinity):
even spread when possible, never blocking. Then the rollout deadlocks: the old pods' required anti-affinity
also applies to the *new* pods (the scheduler checks existing pods' terms against an incoming pod), so the
new ReplicaSet's pods are Pending; and the old ReplicaSet can't shrink, because 3 of 5 available is already
below `replicas - maxUnavailable`. Delete the old ReplicaSet (or scale to 0 and back) to finish it.

**Interview notes**
- Required anti-affinity is right for "never two on one node" (e.g. quorum members), wrong for "spread
  please". Topology spread expresses "as even as possible" with a max skew.
- Changing away from required anti-affinity needs a plan for the rollout (Recreate, or remove the old RS):
  a classic stuck `kubectl rollout status`.
- `topologySpreadConstraints` with `DoNotSchedule` counts every node as a domain - including the tainted
  control plane, which then holds 0 pods and caps each worker at `maxSkew` = 1 (3 run, 2 Pending again). Add
  `nodeTaintsPolicy: Honor` (or use `ScheduleAnyway`, which only scores).
- Inter-pod affinity is expensive for the scheduler in big clusters; topology spread scales better.
- Zones: the same with `topology.kubernetes.io/zone` - uneven zones + DoNotSchedule is S05.
