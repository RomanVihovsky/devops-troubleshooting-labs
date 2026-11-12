# O07 - what drain refuses, and why

**Root cause**: `kubectl drain` refuses by default to do anything that loses something:
- DaemonSet pods: evicting them is pointless (the DaemonSet ignores `unschedulable` and would recreate them).
  `--ignore-daemonsets` leaves them in place.
- Pods with emptyDir: their local data is lost. `--delete-emptydir-data` accepts that.
- Pods without a controller: nothing will recreate them. `--force` deletes them anyway.

**Fix**: `kubectl drain k8s-w2 --ignore-daemonsets --delete-emptydir-data --force`, then `kubectl uncordon k8s-w2`.
(The drain was attempted once and left the node cordoned; that's why uncordon is part of every runbook.)

**Interview notes**
- Drain = cordon + evict (Eviction API, honours PDBs: W12) + wait. `--timeout` and `--disable-eviction` (plain
  deletes, bypassing PDBs) exist. Use the latter only in emergencies.
- Bare pods are lost forever; that's the point of controllers. Debug pods should be `kubectl debug`/
  `kubectl run --rm`.
- Graceful node shutdown (kubelet `shutdownGracePeriod`) is the "drain" for unplanned reboots.
