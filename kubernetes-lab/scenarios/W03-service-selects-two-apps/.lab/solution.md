# W03 - one selector, two Deployments

**Root cause**: `admin` was copied from `web` and kept `app: web` in its pod labels. Service `web` selects
`app: web` only, so its EndpointSlices held the pods of both Deployments and kube-proxy balanced over all of
them.

**Diagnosis**
```
kubectl -n market get endpointslices -l kubernetes.io/service-name=web -o wide
kubectl -n market get pods -o wide --show-labels
kubectl -n market get pods -l app=web -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[0].name
```

**Fix**: a selector only `web`'s pods match (`app: web, role: frontend`). Better still, give `admin` its own
`app: admin` (that needs a new Deployment: selectors are immutable, W02).

**Interview notes**
- Services, NetworkPolicies, PDBs and Deployments all select by labels, and none of them knows about the
  others. Overlapping selectors are a silent bug: traffic splits, PDBs count the wrong pods, two Deployments
  fight over pods (the API rejects overlapping RS selectors only within one Deployment).
- Use the recommended labels (`app.kubernetes.io/name`, `instance`, `component`), and select on name +
  instance.
- `kubectl get endpointslices` is the first check for "the Service answers with the wrong thing".
