## Hint 1
No pods: look at the ReplicaSet's events (`kubectl -n sandbox describe rs -l app=notifier`).

## Hint 2
`kubectl -n sandbox describe resourcequota` shows Used vs Hard. Admission refuses a pod that would go over.

## Hint 3
`kubectl -n sandbox patch resourcequota sandbox --type merge -p '{"spec":{"hard":{"pods":"5"}}}'`. The
ReplicaSet retries by itself (with back-off).
