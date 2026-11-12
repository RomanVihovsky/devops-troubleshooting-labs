## Hint 1
`systemctl status kubelet` and `journalctl -u kubelet -n 50 --no-pager` on k8s-w2: what does it fail to
parse?

## Hint 2
Kubernetes quantities: `Mi`/`Gi` (binary) or `M`/`G` (decimal) - `MB` is not a Kubernetes unit.

## Hint 3
`memory.available: "200Mi"` in `evictionHard`, then `systemctl restart kubelet`.
