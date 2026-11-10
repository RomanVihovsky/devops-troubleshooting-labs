## Hint 1
`kubectl get storageclass` - which one says `(default)`? `kubectl -n wiki describe pvc wiki-data`.

## Hint 2
The default is an annotation: `storageclass.kubernetes.io/is-default-class: "true"`.

## Hint 3
`kubectl patch storageclass local-path -p '{"metadata":{"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'`.
Since 1.28 the pending PVC gets the default class assigned retroactively.
