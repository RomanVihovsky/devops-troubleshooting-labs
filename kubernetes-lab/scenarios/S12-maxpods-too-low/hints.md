## Hint 1
`kubectl describe node k8s-w1 | grep -A6 -E 'Capacity|Allocatable'` - look at `pods`. Then
`kubectl get pods -A -o wide --field-selector spec.nodeName=k8s-w1 | wc -l`.

## Hint 2
The pod capacity of a node comes from the kubelet: `maxPods` in `/var/lib/kubelet/config.yaml` (default 110).
The scheduler only sees what the kubelet reports.

## Hint 3
On each worker: remove the `maxPods:` line (or set `maxPods: 110`) in `/var/lib/kubelet/config.yaml`, then
`sudo systemctl restart kubelet`. The Pending pods schedule once the nodes report the new capacity.
