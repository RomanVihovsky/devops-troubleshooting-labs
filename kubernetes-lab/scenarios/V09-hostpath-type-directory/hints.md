## Hint 1
`kubectl -n agent describe pod <pod>` - the event says which check failed.

## Hint 2
hostPath `type: Directory` requires the directory to exist already; `DirectoryOrCreate` creates it (0755,
root).

## Hint 3
`type: DirectoryOrCreate` in `spool-agent.yaml`, apply.
