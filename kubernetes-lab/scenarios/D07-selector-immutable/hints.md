## Hint 1
`argocd app get demo`: which resource failed, and why? `git -C workspace/gitops log -p -1 -- charts/labapp`
shows what the refactor changed.

## Hint 2
A Deployment's `spec.selector` can't change after creation. The Service applied fine (its selector is
mutable) - compare `kubectl -n demo get svc demo -o jsonpath='{.spec.selector}'` with the Deployment's. The
next version bump would leave that Service with no endpoints at all.

## Hint 3
Keep selectors stable and put changing values (version) only on the pod template labels. `git revert` the
chart commit (or move the version line back out of `labapp.selectorLabels`), push, refresh demo and shop.
