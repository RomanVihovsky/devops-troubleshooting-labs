# B01 - four faults behind one 502

1. **Service selector** `app: catalog-api` vs pod label `app: catalog` -> no endpoints (N01).
2. **default-deny without DNS**: egress is denied for every pod, the allow rules cover web -> catalog:8080 but not
   CoreDNS - `catalog` doesn't even resolve (X01). Add an egress rule to `kube-system`/`k8s-app: kube-dns` on 53
   UDP+TCP.
3. **HPA without CPU requests**: utilization is usage / request; no request, no metric - the HPA can't scale (R01).
4. **PDB `minAvailable: 3` with 3 replicas**: 0 allowed disruptions, every drain hangs (W12). `maxUnavailable: 1`
   keeps protection and lets one pod move (the HPA's minReplicas is 3, so 2 stay up).

**Order that saves time**: follow the request (DNS -> Service -> pods), then capacity (HPA), then operations (PDB).
`kubectl -n bf get endpointslices,networkpolicy,hpa,pdb` shows all four in one screen.

**Interview notes**
- Boss fights are how real outages look: several latent faults, each hiding the next. Fix, re-test, repeat.
- Verify from outside the namespace (a test pod in `default`) - inside, default-deny blocks your own probe.
