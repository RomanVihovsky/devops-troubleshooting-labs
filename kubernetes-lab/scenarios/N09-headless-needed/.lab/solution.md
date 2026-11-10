# N09 - peer discovery needs a headless Service

**Root cause**: `peers` is a ClusterIP Service: DNS returns its single virtual IP. The app expects one A
record per member.

**Fix**: `clusterIP: None` (immutable field → delete + recreate the Service).

**Interview notes**
- Headless Services: DNS A/AAAA records per ready endpoint, SRV records per port; StatefulSets add stable
  names (`pod-0.svc.ns`). `publishNotReadyAddresses: true` lists members before they're Ready (bootstrap of
  quorum systems).
- Client-side load balancing / gossip / databases with their own replication want pod IPs; everything
  else wants the ClusterIP.
