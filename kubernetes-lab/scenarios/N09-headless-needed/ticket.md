# ring: every member thinks it's alone
**INC-2609** · P3 · Reporter: platform team

Our 3-member `ring` service discovers its peers by resolving `peers.ring` - one DNS A record per member pod
(that's how it worked on the old platform). Here the DNS name returns a single IP, so each member sees one
"peer" that isn't even a pod. Manifests: `workspace/N09/ring.yaml` (namespace `ring`).

**Test**: `peers.ring.svc.cluster.local` resolves to the 3 ring pod IPs; the ring keeps 3 replicas.
