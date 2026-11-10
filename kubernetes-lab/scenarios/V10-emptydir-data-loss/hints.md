## Hint 1
`kubectl -n notes get deploy notes -o jsonpath='{.spec.template.spec.volumes}'`.

## Hint 2
`emptyDir` lives exactly as long as the pod.

## Hint 3
A PersistentVolumeClaim (local-path is fine for one replica; `strategy: Recreate` so the new pod can mount
it) mounted at `/data`.
