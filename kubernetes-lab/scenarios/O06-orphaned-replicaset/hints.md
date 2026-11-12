## Hint 1
`kubectl -n retired get rs,pods --show-labels` - who owns the pods now (`metadata.ownerReferences`)?

## Hint 2
`--cascade=orphan` deletes only the Deployment; its ReplicaSet is left without an owner, and it keeps its pods
running (it's a controller of its own).

## Hint 3
`kubectl -n retired delete rs -l app=oldapp` (the default cascade deletes its pods).
