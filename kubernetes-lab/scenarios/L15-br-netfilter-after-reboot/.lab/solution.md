# L15 - a kernel module that only the last boot remembered

**Root cause**: `br_netfilter` was removed from `/etc/modules-load.d/k8s.conf`. It stayed loaded until the
reboot. After it, `systemd-modules-load` didn't load it, so the `net.bridge.*` keys didn't exist when
`systemd-sysctl` applied `/etc/sysctl.d/90-k8s.conf` (errors in the journal). With Calico's routed pod
network nothing broke: traffic doesn't cross a Linux bridge. Kubernetes' install requirements still list the
module, and anything bridged (a CNI with a bridge, `kubenet`, Docker) would lose iptables filtering of bridged
traffic: Services and NetworkPolicies silently bypassed.

**Diagnosis**
```
./lab node w3
lsmod | grep br_netfilter                         # nothing
sysctl net.bridge.bridge-nf-call-iptables         # No such file or directory
sudo journalctl -b -u systemd-sysctl -u systemd-modules-load
cat /etc/modules-load.d/*.conf
```

**Fix**: `br_netfilter` back in `/etc/modules-load.d/k8s.conf`, then `modprobe br_netfilter && sysctl --system`.
The test reboots the node to prove it persists.

**Interview notes**
- Boot order: `systemd-modules-load` → `systemd-sysctl`. A sysctl for a module that isn't loaded is lost
  without failing the boot.
- Reboot-surfacing faults (a module, swap in fstab, a disabled unit) pass every check until the next reboot.
  Patch rollouts that reboot nodes one by one are when you find them. Test with a reboot.
- kubeadm ≥ 1.30 no longer checks `bridge-nf-call-iptables` in its preflight, so nothing reminds you.
- Node baselines belong in config management (or the image), not in a one-time install script.
