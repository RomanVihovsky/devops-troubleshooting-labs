## Hint 1
`argocd app get billing` shows the phase and the hook it waits for. `kubectl -n billing get pods` and
`kubectl -n billing describe pod -l app.kubernetes.io/name=labapp-migrate`: why doesn't the container start?

## Hint 2
Argo CD runs **PreSync** hooks before any normal (Sync-phase) resource is applied. The Job reads its settings
from the chart's ConfigMap `billing` (`envFrom`) - a Sync-phase object. While the operation runs, a new
commit won't sync either: `argocd app terminate-op billing`.

## Hint 3
Make the ConfigMap part of PreSync too, ordered before the Job: in `envs/billing/values.yaml` set
`config.annotations: {argocd.argoproj.io/hook: PreSync, argocd.argoproj.io/hook-delete-policy:
BeforeHookCreation, argocd.argoproj.io/sync-wave: "-1"}` (the chart got that knob this week). Push, `argocd app terminate-op billing`, then
`argocd app sync billing`.
