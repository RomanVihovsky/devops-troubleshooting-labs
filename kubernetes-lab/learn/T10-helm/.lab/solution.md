# T10 - solution and takeaways

```
helm lint labapp; helm template web labapp -f values-t10.yaml
helm install web ./labapp -n t10 -f values-t10.yaml                                  # rev 1: 1.3
helm upgrade web ./labapp -n t10 -f values-t10.yaml --set image.tag=1.4              # rev 2: 1.4
helm upgrade web ./labapp -n t10 -f values-t10.yaml --set image.tag=1.5 --wait --timeout 90s   # rev 3: failed
helm rollback web 1 -n t10                                                           # rev 4: "Rollback to 1"
kubectl -n t10 get secrets -l owner=helm,name=web                                    # 4 Secrets
```

**Takeaways**
- Values precedence: chart defaults < `-f` files (in order) < `--set`/`--set-string`. `helm get values`
  shows only what *you* supplied; `--all` the merged result. Reusing an upgrade without `-f` drops your
  file's values unless `--reuse-values` (which brings its own surprises).
- A release is a stored object: one Secret per revision (gzip+base64 JSON with chart, values and the
  rendered manifest), capped by `--history-max`. Delete those and Helm forgets the release, not the objects.
- Without `--wait` a crashing release is "deployed". `--wait` makes it fail; `--rollback-on-failure`
  (`--atomic` in Helm 3) rolls back by itself.
- `rollback` never goes "back": it creates a new revision with old content. Under Argo CD the cluster is
  driven from Git instead - a rollback there is a Git revert (T11, D domain).
