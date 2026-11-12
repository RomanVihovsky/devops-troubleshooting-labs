## Hint 1
`kubectl -n orders get deploy,pods` and `kubectl -n orders describe pod -l app=orders-migrate`: last state, exit
code, restart count. Which `restartPolicy` does a Deployment's pod have?

## Hint 2
Deployments (and ReplicaSets) keep a process **running**: their pods must use `restartPolicy: Always`, so a
container that exits - even with 0 - is restarted, with back-off. Run-to-completion work is a Job.

## Hint 3
Delete the `orders-migrate` Deployment and create a Job with the same container
(`restartPolicy: Never` or `OnFailure`, a `backoffLimit`). `kubectl -n orders wait --for=condition=complete job/orders-migrate`.
