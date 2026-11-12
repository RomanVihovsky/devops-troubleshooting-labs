## Hint 1
`journalctl -u kubelet -b -n 30` on k8s-w2. `swapon --show`, `free -h`.

## Hint 2
The kubelet refuses to start with swap on (`failSwapOn: true`, the default) unless swap support is
configured explicitly. Where does swap come from at boot?

## Hint 3
`swapoff -a`, remove the swap line from `/etc/fstab`, `systemctl restart kubelet`.
