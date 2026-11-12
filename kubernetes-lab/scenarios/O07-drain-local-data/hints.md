## Hint 1
Run `kubectl drain k8s-w2` and read each refusal: each one has its own flag.

## Hint 2
`--ignore-daemonsets` (their pods stay; the DaemonSet would recreate them anyway), `--delete-emptydir-data` (local
emptyDir data is lost), `--force` (pods without a controller are deleted and never come back).

## Hint 3
`kubectl drain k8s-w2 --ignore-daemonsets --delete-emptydir-data --force`, wait for it to finish, then
`kubectl uncordon k8s-w2`.
