## Hint 1
`kubectl describe node k8s-w1` → conditions. On the node: `systemctl status containerd`, `journalctl -u
containerd -n 30`.

## Hint 2
`containerd config dump` parses the config the same way the daemon does - read the TOML error: line and
column. A table header needs its closing bracket.

## Hint 3
Closing the bracket isn't enough: the file already has a `[plugins.'io.containerd.cri.v1.images']` table,
and TOML forbids defining a table twice. Delete the appended block and put `max_concurrent_downloads = 10`
under the existing header (before its sub-tables). `containerd config dump`, then `systemctl restart
containerd`.
