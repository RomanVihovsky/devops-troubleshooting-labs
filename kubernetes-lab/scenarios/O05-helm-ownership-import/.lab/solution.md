# O05 - adopting existing objects into a Helm release

**Root cause**: the chart renders a Service `web`, and one already exists (created by hand). Helm never silently
takes over objects it didn't create: it adopts only objects marked as belonging to **this** release
(`app.kubernetes.io/managed-by: Helm`, annotations `meta.helm.sh/release-name` and `release-namespace`).
Otherwise the install fails with *invalid ownership metadata*.

**Diagnosis**
```
helm install web charts/labapp -n importx -f workspace/O05/values.yaml    # the error names the missing keys
kubectl -n importx get svc web -o jsonpath='{.metadata.labels} {.metadata.annotations}'; echo
```

**Fix**: add the label + annotations to the existing Service, install. Helm then adopts the object in place
(same UID, no gap for its clients).

**Interview notes**
- The alternative (delete the Service, let Helm create it) changes its ClusterIP and drops connections. Adoption
  keeps the object.
- The same metadata moves an object between releases. A release can't adopt an object that another release
  owns.
- `helm uninstall` deletes adopted objects too. Use the annotation `helm.sh/resource-policy: keep` for
  objects that must survive.
