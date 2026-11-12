## Hint 1
`kubectl -n dbs get database orders-db -o yaml` - look at `metadata.deletionTimestamp` and `metadata.finalizers`.

## Hint 2
A finalizer is a "please wait for me" note from a controller. With the controller gone, nobody removes it - and
the API server won't delete the object until it's removed.

## Hint 3
`kubectl -n dbs patch database orders-db --type merge -p '{"metadata":{"finalizers":null}}'` (only that one).
