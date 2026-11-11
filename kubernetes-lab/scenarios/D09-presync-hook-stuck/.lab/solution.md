# D09 - a PreSync hook that needs a Sync-phase resource

**Root cause**: Argo CD maps Helm's `pre-install,pre-upgrade` hooks to **PreSync**. A sync runs in phases:
PreSync hooks first, then the normal resources (the Sync phase), then PostSync. The migration Job takes its
settings from the chart's ConfigMap `billing` (`envFrom`) and `DATABASE_PASSWORD` from Secret `db-creds`, which
the chart's SealedSecret creates. Both are normal resources, applied in the Sync phase. The Job's pod waited in
`CreateContainerConfigError` for objects that could only appear after the Job finished. The operation hung in *Running* until the Job's
`activeDeadlineSeconds`.

**Diagnosis**
```
argocd app get billing               # Phase: Running - waiting for completion of hook batch/Job/billing-migrate
kubectl -n billing get pods          # billing-migrate-...  CreateContainerConfigError
kubectl -n billing describe pod -l app.kubernetes.io/name=labapp-migrate   # secret "db-creds" not found
kubectl -n billing get sealedsecret  # nothing yet - the Sync phase never started
```

**Fix**: whatever the hook needs must exist before the hook, so it belongs in PreSync too, ordered earlier:
```yaml
x-presync: &presync
  argocd.argoproj.io/hook: PreSync
  argocd.argoproj.io/hook-delete-policy: BeforeHookCreation
  argocd.argoproj.io/sync-wave: "-1"          # the Job's helm hook-weight 0 maps to wave 0
config:
  annotations: *presync                      # the settings ConfigMap
secrets:
  sealedSecret:
    annotations: *presync
```
A fix of only the Secret leaves the pod waiting for `configmap "billing" not found`.
Then `argocd app terminate-op billing` (a running operation blocks every new sync) and sync again.

**Interview notes**
- The phase order is PreSync → Sync → PostSync (→ SyncFail), with waves inside each phase. Hooks are not
  "just early resources": Sync-phase resources don't exist yet while PreSync runs.
- Other valid designs: the credentials come from somewhere that already exists (an ExternalSecret synced
  earlier, a separate app or wave), or the app migrates itself at start-up behind a readiness gate.
- `activeDeadlineSeconds` on hook Jobs turns "hangs forever" into a failed sync you can see. Without it,
  only `terminate-op` ends the operation.
- Everything the hook's pod needs counts: the Secret here, but also its **ServiceAccount**. With the chart's
  own SA (a Sync-phase resource) the Job couldn't even create its pod ("serviceaccount not found"), which is
  why billing runs as the namespace's `default` SA.
- Hook delete policies: `BeforeHookCreation` (recreate each sync), `HookSucceeded` (clean up), `HookFailed`.
