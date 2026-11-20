## Hint 1
Start at the bottom: `kubectl -n orders-db get pvc,pods`, `kubectl -n orders-db describe pvc data-postgres-0`,
`kubectl get storageclass`. Then the pod's events, then the app's `/ready` (`kubectl -n orders-db exec deploy/orders --
labapp get localhost:8080/ready`).

## Hint 2
Three problems: the PVC asks for a StorageClass that doesn't exist (and `volumeClaimTemplates` can't be edited in place
- V06); the password comes from a key the Secret doesn't have (`kubectl -n orders-db get secret postgres-auth -o
jsonpath='{.data}'`); per-pod DNS names (`postgres-0.postgres`) exist only behind a **headless** Service.

## Hint 3
Delete the StatefulSet and its Pending PVC, fix the class (`local-path` or none = default) and the `secretKeyRef` key,
make Service `postgres` headless (`clusterIP: None` - immutable, so delete and re-create it), apply. orders
reconnects and migrates by itself.
