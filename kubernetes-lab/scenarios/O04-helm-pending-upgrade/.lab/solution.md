# O04 - a release stuck in pending-upgrade

**Root cause**: Helm stores each release revision as a Secret (`sh.helm.release.v1.web.vN`) with a status. An
upgrade first writes the new revision as `pending-upgrade`, applies, waits, then marks it `deployed`. The CI
runner was killed during `--wait`, so revision 2 stayed `pending-upgrade` forever. Helm treats that as "another
operation is running" and refuses new ones.

**Diagnosis**
```
helm history web -n helmx                 # 2  pending-upgrade
kubectl -n helmx get secrets -l owner=helm,name=web -L status,version
```

**Fix**: `helm rollback web 1 -n helmx` (back to the last deployed revision; that operation clears the pending
state), then the real upgrade. The killed revision stays in `helm history` as `pending-upgrade`, harmless once a
newer revision is deployed. Alternative: delete the pending revision's Secret.

**Interview notes**
- Every helm operation = a release record. A killed client (Ctrl-C, CI timeout, OOM) can leave `pending-*`
  states. Give CI enough time (`--timeout`), use `--atomic` (roll back on failure; `--rollback-on-failure`
  in Helm 4), and don't kill helm.
- `helm upgrade --install --atomic --wait` is the usual CI incantation. `--force` replaces resources (deletes and
  re-creates), so it is no fix for this.
- With Argo CD there are no release records at all (D08).
