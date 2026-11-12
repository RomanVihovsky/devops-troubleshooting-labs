# R05 - rejected by a LimitRange

**Root cause**: the namespace's LimitRange requires at least `200m` CPU per container. The pod template requests
`100m`, so the LimitRanger admission plugin rejected every pod the ReplicaSet tried to create (*minimum cpu usage
per Container is 200m, but request is 100m*). Admission errors land on the **ReplicaSet**, not on a pod.

**Diagnosis**
```
kubectl -n team-b get deploy,rs,pods                 # 0 pods
kubectl -n team-b describe rs -l app=worker | tail -5
kubectl -n team-b describe limitrange standard
```

**Fix**: requests (and limits) inside the range: `--requests=cpu=200m`.

**Interview notes**
- LimitRange: per-container/pod min/max, defaults (`default` = limit, `defaultRequest`), and
  `maxLimitRequestRatio`. Applied at admission. Existing pods are never touched.
- "0 pods, nothing to describe": look one level up (ReplicaSet events), then at admission (quota R10,
  LimitRange, PSA A04, webhooks A09).
- Defaults from a LimitRange also explain "where does this limit come from?" when the manifest has none.
