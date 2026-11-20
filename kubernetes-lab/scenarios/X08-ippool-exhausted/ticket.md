# Half of the batch workers never start
**INC-2683** · P2 · Reporter: team data

Namespace `batch` gets its pod IPs from a dedicated Calico pool, `batch-pool` (the firewall team whitelisted that
range for the data warehouse - `workspace/X08/batch-pool.yaml`). Since we scaled `crunch` to 12 workers, only a
few start; the rest hang in *ContainerCreating*: *No IPs available in pools*. The cluster has plenty of
addresses in its default pool, but batch pods must not use it: the warehouse only accepts the batch ranges.
`10.250.0.0/16` is reserved for batch - take what you need from it.

**Test**: `crunch` runs 12 Ready pods; every one of them has an IP from a batch pool inside `10.250.0.0/16`
(namespace `batch` doesn't use the default pool); the default pool is unchanged.
