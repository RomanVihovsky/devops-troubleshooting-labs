## Hint 1
`kubectl -n storefront get events --field-selector reason=Preempted` and `kubectl get priorityclass`. Which pods
have which priority (`kubectl get pods -A -o custom-columns=NAME:.metadata.name,PRIO:.spec.priority`)?

## Hint 2
A pending pod with a higher priority may **preempt** (evict) lower-priority pods to make room - storefront has
priority 0. A PriorityClass also has a `preemptionPolicy`: `PreemptLowerPriority` (default) or `Never` - a pod
that keeps its high place in the scheduling queue but never evicts anyone.

## Hint 3
Either set `preemptionPolicy: Never` on `batch-high` (the field is immutable: delete and re-create the class with
the same value; running pods keep their priority), or give storefront a PriorityClass with a **higher** value.
