## Hint 1
```
helm install web ./labapp -n t10 -f values-t10.yaml
helm upgrade web ./labapp -n t10 -f values-t10.yaml --set image.tag=1.4
```
Precedence: chart `values.yaml` < `-f` files (left to right) < `--set`.

## Hint 2
`helm upgrade web ./labapp -n t10 -f values-t10.yaml --set image.tag=1.5 --wait --timeout 90s` fails and
marks the revision **failed**. Without `--wait`, Helm reports success as soon as the objects are accepted -
and the pods crash anyway. `helm rollback web 1 -n t10` creates a **new** revision that is a copy of 1.

## Hint 3
`kubectl -n t10 get secrets -l owner=helm,name=web` - one `sh.helm.release.v1.web.vN` per revision.
`kubectl -n t10 get secret sh.helm.release.v1.web.v1 -o jsonpath='{.data.release}' | base64 -d | base64 -d
| gunzip | jq '.chart.metadata.version'`.
