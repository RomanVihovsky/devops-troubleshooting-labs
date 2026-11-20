## Hint 1
`./lab node w3`, `dmesg -T | tail` (or `journalctl -k`). What is the kernel dropping, and why?

## Hint 2
*nf_conntrack: table full, dropping packet*: every connection through the node (pod -> Service DNAT included)
needs a conntrack entry; closed TCP connections linger for minutes. Compare `/proc/sys/net/netfilter/nf_conntrack_count`
with `nf_conntrack_max`, and `grep -r conntrack /etc/sysctl.d/`.

## Hint 3
Remove (or fix) the tuning file and raise the limit now: `sysctl -w net.netfilter.nf_conntrack_max=131072`.
(kube-proxy sets this value when it starts - restarting its pod on w3 also restores it, the file would undo it at
the next boot.)
