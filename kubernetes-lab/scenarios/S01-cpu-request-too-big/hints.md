## Hint 1
`kubectl -n render describe pod <pod>` → Events (FailedScheduling). `kubectl describe node k8s-w1` →
"Allocatable" and "Allocated resources".

## Hint 2
The scheduler only sums *requests*, never real usage. How many CPUs does each pod request? How many does a
worker have?

## Hint 3
`resources.requests.cpu: 100m` (and a sensible limit or none), apply.
