# S12 - maxPods, the forgotten capacity

**Root cause**: every worker's kubelet got `maxPods` = the number of pods it ran that day. Pod count is a
resource like CPU: the kubelet reports `status.allocatable.pods`, and the scheduler's NodeResourcesFit filter
rejects a node that is full ("Too many pods"). CPU and memory were idle, the pod slots were not.

**Diagnosis**
```
kubectl -n reports describe pod <pending>                    # 3 Too many pods
kubectl get nodes -o custom-columns=NODE:.metadata.name,PODS:.status.allocatable.pods
kubectl get pods -A -o wide --field-selector spec.nodeName=k8s-w1 --no-headers | wc -l
./lab node w1; sudo grep maxPods /var/lib/kubelet/config.yaml
```

**Fix**: remove `maxPods` (default 110) or set it to a sane value on every worker, restart the kubelet.

**Interview notes**
- Why limit pods at all: each pod costs IPs (the node's pod CIDR: a /24 holds ~250 addresses → 110 by default),
  kubelet/containerd overhead, and conntrack/iptables size. Cloud CNIs (AWS VPC CNI) derive maxPods from ENI
  limits, and that's where people see "Too many pods" in practice.
- Lowering `maxPods` on a live node: the kubelet re-admits the running pods on restart, oldest first. Pods
  beyond the new limit are rejected (`OutOfpods`). Never set it below what runs.
- The scheduler only knows what the kubelet reports: fix the source (kubelet config), not the Node object
  (`kubectl edit node` is overwritten by the kubelet).
