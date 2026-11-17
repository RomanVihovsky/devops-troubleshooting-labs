# notes lost all its data after a "cleanup" commit
**INC-2734** · P1 · Reporter: team notes

`notes` (Argo CD app `notes`, values in `workspace/gitops/envs/notes/values.yaml`) kept its data on a PVC. An
hour ago a colleague committed "drop the PVC (state lives in Redis now)" - it doesn't. Argo CD pruned the PVC, and
`notes` now answers with an empty store. The volume's StorageClass `nfs-retain` keeps released volumes, so the
data should still be there. Get **that** volume back under `notes` - not a new empty one - and make sure a commit
like this can never delete it again.

**Test**: PVC `notes` is Bound to the original volume and `notes` serves its old data again; the PVC is back in
Git with `persistence.enabled: true` and the Argo CD sync option `Prune=false`; app `notes` is Synced and Healthy.
