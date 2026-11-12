# W05 - per-pod DNS needs the governing headless Service

**Root cause**: a StatefulSet's `serviceName` names its **governing Service**. CoreDNS creates
`<pod>.<service>.<ns>.svc.cluster.local` records only for a headless Service (`clusterIP: None`) of that
name. Here only `web-svc` existed: a normal ClusterIP Service with another name. It load-balances fine, but
per-pod names don't exist.

**Diagnosis**
```
kubectl -n kv get sts web -o jsonpath='{.spec.serviceName}'; echo     # web
kubectl -n kv get svc                                                  # web-svc ClusterIP 10.x
kubectl -n kv run t --rm -it --image=busybox:1.37 -- nslookup web-0.web.kv.svc.cluster.local   # NXDOMAIN
```

**Fix**: a headless Service named `web` (selector `app: web`, `clusterIP: None`). Keep `web-svc` for clients
that want one load-balanced address.

**Interview notes**
- Headless: no virtual IP; DNS returns the pod IPs (A records), plus per-pod records for StatefulSets
  (`hostname`/`subdomain`). `publishNotReadyAddresses: true` lets members find each other before they're
  Ready (bootstrapping a quorum).
- `serviceName` is immutable; the Service is not created for you. Helm charts usually render both
  (`<name>` headless + `<name>-client`).
- busybox `nslookup` of a *short* name can fail on search domains; test with FQDNs (FAULTS.md).
