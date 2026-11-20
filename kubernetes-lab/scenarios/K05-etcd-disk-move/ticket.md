# API server unreachable since the etcd disk migration
**INC-2822** · P1 · Reporter: platform team

Tonight's change moved etcd's data from the root disk to the new data disk, mounted at `/var/lib/etcd-disk` on
`k8s-cp1`: etcd was stopped, its data copied, and the static pod manifest updated. Following best practice, the
volume type was changed so that etcd can **never** start on an empty directory. Since then `kubectl` gets *connection
refused*. The data must stay on the new disk, the safety net stays, and of course nothing may be lost.

**Test**: the API answers and all nodes are Ready; etcd runs from `/var/lib/etcd-disk` (the `etcd-data` volume is that
directory with `type: Directory`, and `--data-dir` matches); the ConfigMap `migration-marker` created before the move
still exists.
