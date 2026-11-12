## Hint 1
`kubectl -n catalog exec deploy/catalog -- cat /etc/labapp/app.conf` vs the ConfigMap. How is the file
mounted? (`kubectl -n catalog get deploy catalog -o jsonpath='{.spec.template.spec.containers[0].volumeMounts}'`)

## Hint 2
The kubelet updates ConfigMap volumes by swapping a symlink (`..data`) inside the mounted directory. A `subPath`
mount binds one file at mount time - it never sees the swap.

## Hint 3
Mount the whole ConfigMap at `/etc/labapp` (no `subPath`; `CONFIG_FILE` stays `/etc/labapp/app.conf`), apply.
The new pods read the current file, and later edits arrive within about a minute.
