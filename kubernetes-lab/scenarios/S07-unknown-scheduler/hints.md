## Hint 1
No events = no scheduler has looked at the pod. Which scheduler is the pod waiting for?
`kubectl -n ml get pod <pod> -o jsonpath='{.spec.schedulerName}'`.

## Hint 2
`kubectl -n kube-system get pods -l component=kube-scheduler` - the cluster has one scheduler,
`default-scheduler`.

## Hint 3
Remove `schedulerName` from the pod template (or set `default-scheduler`), apply.
