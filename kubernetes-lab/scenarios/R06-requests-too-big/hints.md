## Hint 1
`kubectl -n analytics2 describe pod -l app=analytics` (Events) and
`kubectl describe node k8s-w1 | grep -A8 'Allocated resources'`.

## Hint 2
The scheduler compares **requests** with each node's allocatable minus what is already requested - actual usage
doesn't matter. A 6Gi request never fits a 4 GiB node.

## Hint 3
`kubectl -n analytics2 set resources deploy/analytics --requests=memory=256Mi --limits=memory=512Mi`.
