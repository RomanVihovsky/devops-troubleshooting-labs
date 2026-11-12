# CHG: patch k8s-w2 - drain refuses
**CHG-9040** · P3 · Reporter: platform team

`k8s-w2` needs its monthly patch. `kubectl drain k8s-w2` refuses: *cannot delete DaemonSet-managed Pods*,
*cannot delete Pods with local storage*, *cannot delete Pods that declare no controller*. In namespace `maint`:
`cache` keeps scratch data in an emptyDir (it rebuilds it - fine to lose), `node-agent` is a DaemonSet, and
`scratch` is a one-off debugging pod from last week (fine to lose). Drain the node, then return it to service.

**Test**: `cache`'s pod and the `scratch` pod that ran on `k8s-w2` are gone (evicted); `k8s-w2` is schedulable again;
`cache` has 2 Ready pods and `node-agent` runs on every worker.
