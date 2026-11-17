## Hint 1
`kubectl -n partners get externalsecrets -o wide` - how many of them have `api-key` as their target? Look at
`spec.target` of each, and at `kubectl -n partners get secret api-key -o yaml` (labels, owner references).

## Hint 2
`creationPolicy: Merge` writes into an existing Secret without owning it - so two ExternalSecrets can write the same
key, each on its own refresh, and the last one wins until the next refresh. Deleting the legacy one in the cluster
won't last: Argo CD's self-heal brings it back from Git.

## Hint 3
In Git: delete `envs/partners/api-key-legacy.yaml`, set `creationPolicy: Owner` in `api-key.yaml`, commit, push,
sync. If ESO refuses to take over the hand-made Secret, delete the Secret once - ESO re-creates it as its owner.
