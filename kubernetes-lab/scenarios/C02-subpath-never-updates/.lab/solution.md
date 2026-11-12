# C02 - subPath mounts are frozen

**Root cause**: the "volume cleanup" mounted the single file with `subPath: app.conf`. A ConfigMap volume is a
directory the kubelet updates atomically: it writes a new timestamped directory and swaps the `..data`
symlink. A `subPath` mount bind-mounts the file that existed when the container started. It never follows
the swap. labapp re-read the same stale file on every request.

**Diagnosis**
```
kubectl -n catalog get cm catalog-files -o jsonpath='{.data.app\.conf}'
kubectl -n catalog exec deploy/catalog -- cat /etc/labapp/app.conf        # still Hello
kubectl -n catalog get deploy catalog -o jsonpath='{.spec.template.spec.containers[0].volumeMounts}'; echo
```

**Fix**: mount the ConfigMap as a directory (`mountPath: /etc/labapp`, no `subPath`). New pods see the
current content, and later edits arrive after the kubelet's sync (about a minute).

**Interview notes**
- `subPath` exists to put one file into a directory that has other files (e.g. `nginx.conf` into
  `/etc/nginx`, C04). The price: no updates, ever. Alternatives: mount the directory elsewhere and point the
  app there, or use `items:` to choose files without `subPath`.
- Update latency = kubelet sync period + ConfigMap cache TTL (`configMapAndSecretChangeDetectionStrategy`).
  Not instant, not transactional across pods.
- The app must re-read the file (inotify or per request). Otherwise you still need a rollout (C01).
