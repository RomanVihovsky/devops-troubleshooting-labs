## Hint 1
`kubectl -n search-cache describe pod <pod>`: Last State, Reason, Exit Code - and the container's limits.

## Hint 2
A container whose memory goes above `limits.memory` is killed by the kernel's OOM killer. 192 MB of cache +
the Python runtime vs the limit?

## Hint 3
Raise `resources.limits.memory` (and the request) to e.g. 320Mi in `cache.yaml`, apply.
