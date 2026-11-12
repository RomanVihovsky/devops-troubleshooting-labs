## Hint 1
`argocd app get payments` (or the UI) shows the condition. `kubectl -n argocd get appproject team-a -o yaml`.

## Hint 2
An AppProject restricts `sourceRepos`, `destinations` (server + namespace) and cluster-scoped kinds
(`clusterResourceWhitelist`). Compare the app's destination with the project's list.

## Hint 3
In `apps/project-team-a.yaml` add `{server: https://kubernetes.default.svc, namespace: payments}` to
`spec.destinations` (or fix the typo'd one), push, refresh `lab-apps`, then `payments`.
