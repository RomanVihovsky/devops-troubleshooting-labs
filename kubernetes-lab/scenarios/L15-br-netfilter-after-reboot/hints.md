## Hint 1
`./lab node w3`: `lsmod | grep br_netfilter`, `sudo journalctl -b -u systemd-sysctl`, and compare
`/etc/modules-load.d/` with a healthy worker's.

## Hint 2
The `net.bridge.*` keys exist only while the `br_netfilter` module is loaded. `systemd-modules-load` loads the
modules listed in `/etc/modules-load.d/*.conf` at boot - before `systemd-sysctl` applies `/etc/sysctl.d`.

## Hint 3
Add `br_netfilter` back to `/etc/modules-load.d/k8s.conf` (next to `overlay`), then for now:
`sudo modprobe br_netfilter && sudo sysctl --system`.
