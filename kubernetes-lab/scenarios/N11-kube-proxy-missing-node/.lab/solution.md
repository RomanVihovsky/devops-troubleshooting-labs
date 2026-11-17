# N11 - no kube-proxy on one node

**Root cause**: a node affinity (`kubernetes.io/hostname NotIn [k8s-w2]`) on the kube-proxy DaemonSet - the eBPF
pilot that never happened - removed kube-proxy from `k8s-w2`. kube-proxy writes each node's Service rules
(iptables here); its old rules on w2 stay behind, so Services that existed before keep working, but nothing created
or changed since is programmed there: `pricing`'s ClusterIP goes nowhere from w2's pods.

**Diagnosis**
```
kubectl -n kube-system get pods -l k8s-app=kube-proxy -o wide      # 3 pods, none on k8s-w2
kubectl -n kube-system get ds kube-proxy -o jsonpath='{.spec.template.spec.affinity}'
./lab node w2 ; sudo iptables-save | grep -c pricing                # 0
```

**Fix**: drop the affinity; the DaemonSet schedules kube-proxy on w2 and it syncs every Service at start-up.

**Interview notes**
- "Old Services work, new ones don't, only on one node" = a stale data plane: kube-proxy (or the CNI's replacement
  like Cilium's kube-proxy-free mode) not running or not syncing.
- kube-proxy modes: iptables, ipvs, nftables (GA 1.33); `--cleanup` removes its rules - what you'd do when really
  replacing it.
- DaemonSets and node-level components: check `desiredNumberScheduled` against the node count, and tolerations
  for tainted nodes.
