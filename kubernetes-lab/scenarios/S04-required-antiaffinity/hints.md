## Hint 1
`kubectl -n gateway describe pod <pending pod>` - which rule rejects every node?

## Hint 2
`requiredDuringSchedulingIgnoredDuringExecution` anti-affinity per hostname = at most one pod per node.
3 workers, 5 replicas.

## Hint 3
Make it soft (`preferredDuringScheduling...` with a weight) or use `topologySpreadConstraints` (`maxSkew:
1`, `topologyKey: kubernetes.io/hostname`, `whenUnsatisfiable: ScheduleAnyway`), apply. If the new pods stay Pending too: the *old* pods' required
anti-affinity still repels every pod labelled `app=gateway` (anti-affinity is symmetric), and the rollout
can't remove them - delete the old ReplicaSet (`kubectl -n gateway get rs`).
