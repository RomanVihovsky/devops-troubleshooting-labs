## Hint 1
`kubectl -n uploads describe pvc uploads-data` - Events. `kubectl get storageclass`.

## Hint 2
The PVC asks for a class this cluster doesn't have. `storageClassName` of a PVC can't be changed after
creation.

## Hint 3
Set `storageClassName: local-path` (or remove it: the default class is used), delete the PVC (and the pod
holding it), apply again.
