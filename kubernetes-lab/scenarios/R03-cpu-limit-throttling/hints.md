## Hint 1
`kubectl -n quotes get deploy quotes -o jsonpath='{.spec.template.spec.containers[0].resources}'`. Then on the
node of a quotes pod: `cat /sys/fs/cgroup/kubepods.slice/.../cpu.stat` - look at `nr_throttled` and
`throttled_usec` (or `kubectl top pods` vs the limit).

## Hint 2
A CPU **limit** is a quota per 100 ms period (CFS): with `50m` the container may run 5 ms per 100 ms, then it
waits. A request that needs 20 ms of CPU takes ~400 ms of wall time - and queues behind the others.

## Hint 3
Raise the limit (e.g. `1`) or remove it, keep the request:
`kubectl -n quotes set resources deploy/quotes --limits=cpu=1 --requests=cpu=100m`.
