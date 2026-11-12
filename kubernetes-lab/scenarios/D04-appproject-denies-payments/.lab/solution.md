# D04 - the AppProject didn't permit the destination

**Root cause**: `team-a`'s `destinations` list `namespace: payment`; the app deploys to `payments`. Argo CD
refuses before rendering anything: *application destination ... namespace payments do not match any of the
allowed destinations in project team-a* (InvalidSpecError).

**Diagnosis**
```
argocd app get payments                       # condition InvalidSpecError
kubectl -n argocd get appproject team-a -o jsonpath='{.spec.destinations}'
```

**Fix**: correct the destination in `apps/project-team-a.yaml` (Git - lab-apps would revert a kubectl edit),
push, refresh.

**Interview notes**
- AppProjects are Argo CD's tenancy boundary: `sourceRepos`, `destinations`, `clusterResourceWhitelist` /
  `namespaceResourceBlacklist`, project roles (RBAC for the UI/CLI), sync windows.
- "Fix" options that pass the test but fail the review: `namespace: "*"`, moving the app to `default`
  (which allows everything), or `sourceRepos: ["*"]`.
- Cluster-scoped kinds (Namespace, CRDs, ClusterRoles) are denied by default: `CreateNamespace=true` or an
  app that ships its Namespace needs `{group: "", kind: Namespace}` whitelisted.
