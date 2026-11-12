## Hint 1
`kubectl -n edge describe pod <pending pod>`; `kubectl -n edge get ds node-probe -o yaml | grep -B2 -A2
hostPort`.

## Hint 2
A `hostPort` reserves that port on the node's IP: only one pod per node can have it. Does edge-proxy need
a host port at all, if clients use its Service?

## Hint 3
Remove `hostPort` from edge-proxy's container port, apply.
