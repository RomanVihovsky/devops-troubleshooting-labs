# payments-api keeps getting evicted on k8s-w2
**INC-2421** · P1 · Reporter: team payments

Since the kubelet "hardening" on `k8s-w2` this morning, pods there are evicted again and again (*The node was
low on resource: memory*) - our batch job first - and `k8s-w2` shows `MemoryPressure`. `free -m` on the node
shows plenty of memory. `payments-api` is pinned to `k8s-w2` (licence-bound) and must survive the next real
memory crunch better than the batch jobs next to it - it's next in line.

**Test**: `k8s-w2` has no MemoryPressure and its kubelet's hard eviction threshold for `memory.available` is
sane for a 4 GiB node (at most 500Mi, or the default); `payments-api` runs 2 Ready pods on `k8s-w2` in the
**Guaranteed** QoS class, stable for 60 s.
