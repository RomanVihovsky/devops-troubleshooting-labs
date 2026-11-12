# T11 - solution and takeaways

```yaml
# apps/t11.yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata: {name: t11, namespace: argocd, finalizers: [resources-finalizer.argocd.argoproj.io]}
spec:
  project: lab
  source: {repoURL: http://git.lab:3000/lab/gitops.git, targetRevision: main, path: charts/labapp,
           helm: {releaseName: t11, valuesObject: {fullnameOverride: t11}}}
  destination: {server: https://kubernetes.default.svc, namespace: t11}
  syncPolicy: {automated: {prune: true, selfHeal: true}, syncOptions: [CreateNamespace=true]}
# apps/project-lab.yaml: spec.destinations += {server: https://kubernetes.default.svc, namespace: t11}
```

**Takeaways**
- App-of-apps: one root Application syncs a directory of Applications (and AppProjects). Adding an app =
  a commit. Edits made with kubectl to anything the root manages are reverted (root has selfHeal).
- Sync status (does live match Git?) and health (does it work?) are independent: *Synced + Degraded* and
  *OutOfSync + Healthy* both happen.
- AppProjects are the multi-tenancy boundary: source repos, destinations, allowed cluster-scoped kinds,
  roles. "not permitted in project" is a policy answer, not a bug (D04).
- `automated` syncs new commits; `selfHeal` also reverts live drift; `prune` deletes what left Git. Without
  the resources finalizer, deleting an Application orphans its objects.
