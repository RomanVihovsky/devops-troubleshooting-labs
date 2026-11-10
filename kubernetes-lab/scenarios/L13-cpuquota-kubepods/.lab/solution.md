# L13 - CPU quota on the whole kubepods slice

**Root cause**: `systemctl set-property kubepods.slice CPUQuota=20%` on k8s-w1 (persisted under
`/etc/systemd/system.control/kubepods.slice.d/`). With the systemd cgroup driver every pod lives below
`kubepods.slice`, so all pods on the node share 0.2 CPU: CFS throttling, probe timeouts, restarts. The node
itself (kubelet, system.slice) is idle - `kubectl top` shows little CPU because the pods can't *use* any.

**Diagnosis**: `cat /sys/fs/cgroup/kubepods.slice/cpu.max` (20000 100000), `cpu.stat` (nr_throttled
growing), `systemctl show kubepods.slice -p CPUQuotaPerSecUSec`, `systemctl cat kubepods.slice`.

**Fix**: `systemctl set-property kubepods.slice CPUQuota=` (or delete the drop-in + daemon-reload).

**Interview notes**
- CPU limits = CFS quota: a pod at its limit is throttled, not killed; latency suffers long before CPU
  graphs look busy. Look at `throttled_usec`, not utilisation.
- The kubelet manages `kubepods.slice` (`--enforce-node-allocatable`, `--kube-reserved`,
  `--system-reserved`); don't tune it by hand with systemd - use the kubelet's reservations.
- Many teams drop CPU *limits* entirely (keep requests) for exactly this reason (R domain).
