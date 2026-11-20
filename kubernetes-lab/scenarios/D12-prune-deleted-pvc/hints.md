## Hint 1
`kubectl get pv | grep nfs-retain` - the old volume is *Released*. `kubectl get pv <pv> -o yaml`: what does
`spec.claimRef` still point to? A Released PV is never bound again automatically.

## Hint 2
Re-enabling persistence in Git alone creates a **new** PVC, which gets a **new** empty volume. Reserve the old PV
for the PVC name the chart will create: replace its `claimRef` with only `{namespace: notes, name: notes}` (no
`uid`, no `resourceVersion`) - it turns *Available*, reserved for that claim.

## Hint 3
Then in Git: `persistence.enabled: true` plus `persistence.annotations: {argocd.argoproj.io/sync-options:
Prune=false}`; commit, push, `argocd app sync notes` (or wait). The new PVC binds to the reserved PV.
