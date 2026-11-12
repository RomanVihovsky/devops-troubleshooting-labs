# W10 - the HPA owns replicas

**Root cause**: an HPA targets `deploy/api` with `minReplicas: 5`. Every sync (15 s) the HPA computes the
desired count, clamps it to [min, max] and writes it to the Deployment's scale subresource. A manual
`kubectl scale` lasts until the next sync.

**Diagnosis**
```
kubectl -n api get hpa api                 # MINPODS 5
kubectl -n api describe hpa api            # "New size: 5; reason: Current number of replicas below Spec.MinReplicas"
```

**Fix**: `minReplicas: 2` in the HPA. Off-peak it settles at 2; under load it can still go to 10.

**Interview notes**
- One owner per field (D06): with an HPA, don't set `replicas` in manifests or scale by hand. Change the
  HPA.
- Scale-down is deliberately slow: `behavior.scaleDown.stabilizationWindowSeconds` defaults to 300 s, so the
  HPA uses the highest recommendation of the last 5 minutes.
- Scheduled scaling (night/day) is a job for KEDA's cron scaler or a CronJob patching `minReplicas`, not
  `kubectl scale`.
