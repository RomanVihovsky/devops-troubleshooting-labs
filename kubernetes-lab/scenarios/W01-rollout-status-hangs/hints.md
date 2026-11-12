## Hint 1
`kubectl -n storefront get rs,pods` and `kubectl -n storefront logs <new pod>`. Why does the rollout neither
finish nor fail?

## Hint 2
A rolling update with `maxUnavailable: 0` waits for each new pod to become Ready; the new pods crash. `rollout
status` only gives up after `progressDeadlineSeconds` - here 3600.

## Hint 3
`kubectl -n storefront rollout undo deploy/storefront`, and
`kubectl -n storefront patch deploy storefront -p '{"spec":{"progressDeadlineSeconds":300}}'`.
