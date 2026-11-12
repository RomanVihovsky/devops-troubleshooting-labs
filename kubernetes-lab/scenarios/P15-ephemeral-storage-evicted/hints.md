## Hint 1
`kubectl -n thumbs get pods` (Evicted/Error ones) and `kubectl -n thumbs describe pod <evicted>`. What counts
toward a container's `ephemeral-storage` limit?

## Hint 2
Ephemeral storage = the container's writable layer + its logs + `emptyDir` volumes (not `medium: Memory`). The
pod's total is checked against the **sum** of its containers' limits; an emptyDir's own `sizeLimit` is checked
too.

## Hint 3
Mount an `emptyDir` with `sizeLimit: 512Mi` at `/tmp/cache` and raise the container's `ephemeral-storage` limit to
cover it (e.g. `600Mi`) - or put `/tmp/cache` on a PVC (not ephemeral). Apply `workspace/P15/thumbs.yaml`.
