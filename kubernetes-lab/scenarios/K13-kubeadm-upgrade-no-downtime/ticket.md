# CHG-1300: upgrade to Kubernetes 1.37 - zero downtime for storefront
**INC-2880** · P2 · Reporter: platform team

The cluster runs Kubernetes **1.36** and must go to **1.37** with `kubeadm` tonight (packages for 1.37 are on every
node). Last week's attempt was aborted: it hung at *draining* the first worker for half an hour. `storefront` (3
replicas, NodePort 30080) must answer the whole time - a prober on `k8s-gw` hits it twice a second and the business
counts every failed probe. Its PodDisruptionBudget exists for a reason: it has to keep protecting storefront.

**Test**: the API server, every kubelet and the kubeadm configuration are on 1.37; no node is left cordoned; storefront
runs 3 Ready replicas and a PodDisruptionBudget still keeps at least 2 of them up; the prober on gw saw at most 2 failed
probes since the start.
