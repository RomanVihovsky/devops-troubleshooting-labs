# edge-proxy won't start: "free ports"
**INC-2511** · P3 · Reporter: edge team

`edge-proxy` (namespace `edge`, `workspace/S11/edge-proxy.yaml`) stays **Pending**: *node(s) didn't have
free ports for the requested pod ports*. The monitoring team's `node-probe` DaemonSet (same namespace)
must keep its port on every node - it's scraped there. Clients reach edge-proxy through its Service.

**Test**: edge-proxy is Running and Ready behind its Service (200 inside the cluster); node-probe still runs
on every worker with its host port.
