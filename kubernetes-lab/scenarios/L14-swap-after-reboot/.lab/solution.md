# L14 - swap turned on at boot

**Root cause**: a swap file in `/etc/fstab`. At boot, systemd activates it; the kubelet starts, sees swap
and exits ("running with swap on is not supported") because `failSwapOn` is true by default. The failure
shows only after a reboot - the change was made days earlier.

**Diagnosis**: `journalctl -u kubelet -b`, `swapon --show`, `grep swap /etc/fstab`.

**Fix**: `swapoff -a`, remove the fstab entry, restart the kubelet.

**Interview notes**
- Faults that surface only at the next reboot: fstab (swap, a dead NFS mount without `nofail`), kernel
  modules (`br_netfilter`), sysctls in `/etc/sysctl.d`, disabled units. Patch reboots find them.
- Swap is supported since 1.28 (NodeSwap, `memorySwap.swapBehavior: LimitedSwap` + `failSwapOn: false`) -
  as a deliberate configuration, not by accident.
