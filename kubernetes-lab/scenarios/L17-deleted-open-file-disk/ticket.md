# k8s-w2 evicts pods for disk space - and the disk looks empty
**INC-2781** · P1 · Reporter: on-call

`k8s-w2` reports *DiskPressure* and has evicted our `audit-ui` pods (they're pinned to it). `df -h /var` says the
disk is over 90 % full, but `du -sh /var/*` adds up to a few GB. Nobody has deleted anything big... except the
security team's new audit spooler, which "rotates its spool by deleting it". The spooler isn't needed on worker
nodes - it was rolled out there by mistake.

**Test**: `k8s-w2` has no DiskPressure and `/var` is below 80 % used; the audit spooler service on w2 is stopped and
disabled; `audit-ui` runs 2 Ready pods on `k8s-w2`.
