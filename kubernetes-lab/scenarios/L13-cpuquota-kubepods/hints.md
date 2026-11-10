## Hint 1
Idle node + slow pods = throttling. On k8s-w1: `cat /sys/fs/cgroup/kubepods.slice/cpu.max` and
`cat /sys/fs/cgroup/kubepods.slice/cpu.stat` (`nr_throttled`, `throttled_usec`).

## Hint 2
With the systemd cgroup driver, kubepods.slice is a systemd unit: `systemctl cat kubepods.slice`,
`systemctl show kubepods.slice -p CPUQuotaPerSecUSec`. Where do drop-ins of `systemctl set-property` live?

## Hint 3
`systemctl set-property kubepods.slice CPUQuota=` (empty = no limit) or remove the drop-in under
`/etc/systemd/system.control/kubepods.slice.d/` and `systemctl daemon-reload`. Check `cpu.max` again.
