## Hint 1
`kubectl -n blog rollout status deploy/blog` and `kubectl -n blog get deploy blog -o yaml | grep -i paus`.

## Hint 2
A paused Deployment records spec changes but doesn't create a new ReplicaSet until it is resumed (used to batch
several changes into one rollout).

## Hint 3
`kubectl -n blog rollout resume deploy/blog`.
