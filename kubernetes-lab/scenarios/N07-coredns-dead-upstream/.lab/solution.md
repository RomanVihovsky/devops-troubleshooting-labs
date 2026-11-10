# N07 - CoreDNS forwards to a dead upstream

**Root cause**: `forward . 10.255.255.1` - nothing answers there. `cluster.local` (kubernetes plugin) and
the `lab` zone (hosts plugin) are answered by CoreDNS itself; everything else goes to the dead forwarder and
times out.

**Fix**: a working upstream (`/etc/resolv.conf` of the node, or the real corporate resolvers).

**Interview notes**
- Split behaviour (internal works, external fails) points at `forward`; nothing works points at CoreDNS
  itself or the kube-dns Service / network path (N06, X09).
- Test the upstream from a node: `dig @IP name`; from a pod: `nslookup name` + CoreDNS `log`/`errors`.
- Timeouts here also slow every lookup with `ndots:5` (each external name is first tried with the search
  suffixes).
