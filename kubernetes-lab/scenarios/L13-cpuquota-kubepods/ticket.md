# k8s-w1 sluggish since the "noisy neighbour" fix
**INC-2330** · P2 · Reporter: search team

Since yesterday everything on k8s-w1 crawls: our `search` pods there fail their probes and restart,
calico-node on w1 restarts too, yet `kubectl top node k8s-w1` shows the node mostly idle. The other workers
are fine. Someone "limited the noisy neighbours" on that node last week.

**Test**: pods on k8s-w1 are not CPU-capped any more (`kubepods.slice` `cpu.max` = `max`), and that
survives a reboot (no persistent setting left); `search` pods on k8s-w1 are Ready without new restarts for
60 s.
