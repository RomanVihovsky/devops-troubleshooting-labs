# R10 - a ResourceQuota that is full

**Root cause**: the namespace's quota allows 2 pods, and `legacy` uses both. The quota admission plugin rejects
the third pod. The error lands on the ReplicaSet (*exceeded quota: sandbox, requested: pods=1, used: pods=2,
limited: pods=2*), so the Deployment just shows 0/1.

**Diagnosis**
```
kubectl -n sandbox describe rs -l app=notifier | tail -3
kubectl -n sandbox describe resourcequota sandbox        # Used / Hard
```

**Fix** (as approved): `hard.pods: "5"`.

**Interview notes**
- Quotas count objects (`pods`, `services`, `count/deployments.apps`) and resources (`requests.cpu`,
  `limits.memory`, `requests.storage`). With a compute quota every pod **must** declare those requests,
  or it's rejected. A LimitRange default helps (R05).
- Scopes (`BestEffort`, `NotTerminating`, PriorityClass) let one quota apply to a subset of pods.
- Rolling updates need headroom: maxSurge pods count against the quota too, and a full quota stalls rollouts.
