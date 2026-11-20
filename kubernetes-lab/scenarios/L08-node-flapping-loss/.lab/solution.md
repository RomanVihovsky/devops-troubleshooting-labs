# L08 - packet loss on the way to the API server

**Root cause**: w1 has a `prio` root qdisc whose band 4 is a `netem loss 90%`, and a `u32` filter that sends every
packet to `192.168.56.20:6443` (the API server load balancer) into that band. The kubelet's lease renewals and
status updates time out most of the time; whenever no renewal gets through for the node-monitor grace period, the
node controller marks w1 NotReady - and the next lucky request makes it Ready again. Everything else (SSH, pod
traffic) is untouched, which is why the node "looks healthy".

**Diagnosis**
```
kubectl get nodes -w ; kubectl -n kube-node-lease get lease k8s-w1 -o jsonpath='{.spec.renewTime}'
./lab node w1
  journalctl -u kubelet --since -10min | grep -iE 'lease|deadline|timeout'
  tc -s qdisc show ; tc filter show dev enp0s8        # netem loss 90%, dropped counters growing
  ping -c 20 192.168.56.20 ; curl -sk --max-time 3 https://192.168.56.20:6443/readyz   # curl times out often
```

**Fix**: `tc qdisc del dev enp0s8 root` (back to the default qdisc).

**Interview notes**
- Node heartbeats: the Lease (every 10 s) and NodeStatus (on change / every 5 min); NotReady after
  `node-monitor-grace-period` without a renewal; pod eviction after the taint's `tolerationSeconds` (300 s).
- Flapping nodes are worse than dead ones: pods are marked, endpoints removed and re-added, controllers churn.
- Real-world causes: a bad NIC/cable, MTU/fragmentation, an overloaded LB, conntrack drops, a saturated uplink -
  netem is how you reproduce them.
