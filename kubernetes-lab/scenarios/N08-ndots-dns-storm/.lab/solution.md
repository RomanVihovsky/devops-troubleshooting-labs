# N08 - ndots:5 turns every short external name into 4 lookups

**Root cause**: a pod's `/etc/resolv.conf` has `search scanner.svc.cluster.local svc.cluster.local cluster.local`
and `options ndots:5`. A name with fewer than 5 dots is treated as relative: the resolver tries it with each
search domain first. `registry.lab` (1 dot) costs 3 x (A + AAAA) = 6 NXDOMAIN answers before the absolute lookup
succeeds - on every call, because NXDOMAIN for `cluster.local` isn't cached here.

**Diagnosis**
```
kubectl -n scanner exec deploy/image-scanner -- cat /etc/resolv.conf
kubectl -n kube-system logs -l k8s-app=kube-dns | grep registry.lab        # with the CoreDNS `log` plugin
kubectl get --raw /api/v1/namespaces/kube-system/pods/<coredns-pod>:9153/proxy/metrics | grep rcode=\"NXDOMAIN\"
```

**Fix** (either):
- make the name absolute: `UPSTREAM_URL=http://registry.lab.:5000/v2/` - one A + AAAA, no search;
- lower the threshold for this workload:
  ```yaml
  dnsConfig:
    options: [{name: ndots, value: "1"}]
  ```

**Interview notes**
- ndots:5 exists so `svc.ns` and `svc.ns.svc` short names resolve; lowering it breaks those for this pod - use
  FQDNs for cluster services then (`svc.ns.svc.cluster.local.`).
- NodeLocal DNSCache and CoreDNS `autopath` reduce the cost cluster-wide; musl (Alpine) resolvers behave
  differently from glibc (no parallel A/AAAA, different search handling).
- Symptoms at scale: CoreDNS CPU, conntrack entries for UDP 53, 5 s timeouts from dropped UDP packets.
