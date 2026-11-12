## Hint 1
`kubectl get storageclass nfs-standard -o yaml` - compare with `nfs`. Which field decides whether claims of a
class may grow?

## Hint 2
`allowVolumeExpansion` is one of the few StorageClass fields you **can** change on an existing class, and it
applies to existing claims too.

## Hint 3
`kubectl patch storageclass nfs-standard -p '{"allowVolumeExpansion": true}'`, apply the 2Gi claim again, then
watch `kubectl -n archive get pvc archive-data -w` (the resizer updates `status.capacity`).
