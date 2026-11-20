# O10 - server-side apply: fields have owners

**Root cause**: with server-side apply the API server records, per field, which **manager** set it
(`metadata.managedFields`). On-call's hotfix ran `kubectl apply --server-side --field-manager=ops-hotfix
--force-conflicts` with `LOG_LEVEL=warn`, so `ops-hotfix` became the owner of that env value. When another
applier (`pipeline-inventory`) wants a **different** value for a field it doesn't own, SSA refuses with a
conflict instead of silently overwriting someone else's intent.

**Diagnosis**
```
kubectl -n inventory apply --server-side --field-manager=pipeline-inventory -f inventory-api.yaml   # the conflict
kubectl -n inventory get deploy inventory-api -o yaml --show-managed-fields | less                 # who owns f:env
```

**Fix** (the hotfix is over):
- take ownership: `kubectl apply --server-side --field-manager=pipeline-inventory --force-conflicts -f
  inventory-api.yaml` - `ops-hotfix` loses the field; the next pipeline runs need no force;
- or let `ops-hotfix` release it: apply, as `ops-hotfix`, a configuration without that env entry.

**Interview notes**
- After a forced takeover the old manager may still co-own a list item's **key** (`f:name`): the item would
  survive if the pipeline dropped it. Apply an empty config as `ops-hotfix` to release that too.
- Same value = shared ownership, no conflict; different value from another applier = conflict;
  `kubectl edit`/`patch` (operation `Update`) never conflict - they just take the field.
- Typical real conflicts: HPA vs `spec.replicas` in the manifest (drop replicas from Git), Argo CD/Helm vs
  `kubectl edit`, two controllers fighting over a label.
- `--force-conflicts` in a pipeline by default hides exactly these fights - use it deliberately.
- Client-side apply keeps its state in the `last-applied-configuration` annotation instead; mixing both migrates
  ownership to the `kubectl-client-side-apply` manager.
