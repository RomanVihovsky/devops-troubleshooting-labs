# T12 · Sealed Secrets: scopes, sealing-key backup, key loss and restore
**Learn** · encrypt for the cluster, commit safely, and survive losing the key · ~40 min

The Sealed Secrets controller runs in `kube-system`. Work in `workspace/T12/` (`kubeseal` is in
`./lab env`).

1. Fetch the controller's public cert (`kubeseal --fetch-cert`). Seal three Secrets for namespace `t12`
   and apply them:
   - `api-key` (key `key` = `K3y-t12`) - scope **strict** (name + namespace bound);
   - `shared-config` (key `mode` = `blue`) - scope **namespace-wide**;
   - `banner` (key `text` = `hello`) - scope **cluster-wide**.
   Try renaming the strict one in its YAML and applying it: what happens?
2. **Back up the sealing key** to `workspace/T12/sealing-key.backup.yaml`.
3. **Disaster drill**: delete the sealing key Secret(s) in `kube-system` and restart the controller. It
   creates a brand-new key. Apply `legacy.yaml` (sealed long ago with the old key): it can't be decrypted.
4. **Restore** the key from your backup, restart the controller: `legacy` decrypts.

**Test**: the 3 Secrets decrypted with the right values and scopes; the backup holds the original key; the
controller has more than one key (a new one was made in the drill); `t12/legacy` decrypted.
