# T08 · etcd backup and restore: snapshot, accident, restore
**Learn** · the one backup that brings back a whole cluster's API state · ~40 min

Namespace `t08` holds the ConfigMap `precious`. Practise the full drill on k8s-cp1 (`./lab node cp1`,
`sudo -i`; `etcdctl` and `etcdutl` are installed; the certs are in `/etc/kubernetes/pki/etcd`).

1. **Back up**: an etcd snapshot to **`/var/backups/etcd-t08.db`**, then check it with
   `etcdutl snapshot status`.
2. **The accident**: `kubectl delete namespace t08`. It's gone.
3. **Restore** the snapshot into a **new data dir** (e.g. `/var/lib/etcd-t08`) and point the etcd static pod
   at it. Give the restored member its proper identity (name, peer URL). Wait for the API, then restart the
   API server so it doesn't serve stale cached state.
4. `kubectl -n t08 get cm precious` - back, with its original UID.

**Test**: the snapshot exists and is valid; etcd runs from restored data (a new data dir); `t08` and
`precious` are back with their **original** UIDs (restored, not re-created); the API answers and all nodes
are Ready; only the 4 control-plane manifests are in `/etc/kubernetes/manifests`.
