# N06 - CoreDNS forwards to itself

**Root cause**: `forward . 127.0.0.1` in the Corefile. In the CoreDNS pod, 127.0.0.1:53 *is* CoreDNS: every
upstream query loops. The `loop` plugin sends a probe at start, sees it come back and exits with
"Loop ... detected" - CrashLoopBackOff, cluster DNS gone.

**Fix**: `forward . /etc/resolv.conf` (the node's resolver; careful on systemd-resolved hosts where
`/etc/resolv.conf` points at 127.0.0.53 - the kubelet's `resolvConf` points at
`/run/systemd/resolve/resolv.conf` for that reason).

**Interview notes**
- The classic loop: node resolv.conf → 127.0.0.53 (systemd-resolved) copied into pods; kubelet
  `resolvConf` must point at the real upstreams.
- DNS down = almost everything down (Services by name, image pulls through in-cluster registries, webhooks
  by name). Keep CoreDNS at ≥ 2 replicas on different nodes with a PDB.
- `kubectl run -it --rm dnsutils ... -- nslookup` and the CoreDNS `log` plugin are the debugging tools.
