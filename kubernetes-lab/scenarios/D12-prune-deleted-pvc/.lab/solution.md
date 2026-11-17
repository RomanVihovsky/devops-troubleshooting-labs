# D12 - Argo CD pruned a PVC; getting the Retain volume back

**Root cause**: the app syncs with `prune: true`. The commit set `persistence.enabled: false`, so the chart no
longer renders the PVC and Argo CD **deleted** it. Its StorageClass `nfs-retain` has `reclaimPolicy: Retain`: the
PV and the data survived, but the PV is now *Released* - its `claimRef` still names the deleted claim (with its
UID), and a Released PV is never bound to anything again on its own. Simply re-enabling persistence would create a
new PVC and a new, empty volume.

**Diagnosis**
```
argocd app history notes ; git log -p envs/notes/values.yaml        # the "cleanup" commit
kubectl get pv | grep nfs-retain                                     # Released
kubectl get pv <pv> -o jsonpath='{.spec.claimRef}'                   # the old claim's uid
```

**Fix**:
1. reserve the PV for the claim the chart will create - claimRef with namespace and name only:
   `kubectl patch pv <pv> --type=json -p '[{"op":"replace","path":"/spec/claimRef","value":{"namespace":"notes","name":"notes"}}]'`
   (it becomes *Available*, bindable only by `notes/notes`);
2. Git: `persistence.enabled: true` and `persistence.annotations: {argocd.argoproj.io/sync-options: Prune=false}`;
   commit, push, sync - the new PVC binds to the old volume and the data is back.

**Interview notes**
- `Prune=false` (or `Delete=false`) on stateful resources; `helm.sh/resource-policy: keep` is the Helm
  equivalent. Retain is the last line of defence, not a backup.
- Pre-binding works the other way round too: a PVC with `spec.volumeName: <pv>`.
- Deleting a PVC in use is delayed by the `kubernetes.io/pvc-protection` finalizer until the pod is gone - which
  is why the data loss shows up "on the next rollout".
