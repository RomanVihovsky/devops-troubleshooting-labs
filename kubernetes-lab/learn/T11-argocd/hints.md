## Hint 1
`apps/demo.yaml` is a complete example. For t11: `source.path: charts/labapp`, `helm.releaseName: t11`,
`helm.valuesObject: {fullnameOverride: t11}`, `destination.namespace: t11`, `syncOptions:
[CreateNamespace=true]`. Push, then `argocd app get lab-apps --refresh`.

## Hint 2
`argocd app get t11` shows a condition like *application destination ... namespace t11 is not permitted in
project 'lab'* (InvalidSpecError). Add `{server: https://kubernetes.default.svc, namespace: t11}` to
`spec.destinations` in `apps/project-lab.yaml` and push. An AppProject is the guard rail: allowed source
repos, destinations, cluster-scoped kinds.

## Hint 3
`syncPolicy: {automated: {prune: true, selfHeal: true}, syncOptions: [CreateNamespace=true]}`. Without
`selfHeal`, automated sync reacts only to new commits; live edits stay until someone syncs (D02).
Add `finalizers: [resources-finalizer.argocd.argoproj.io]` if deleting the Application should delete its
resources too.
