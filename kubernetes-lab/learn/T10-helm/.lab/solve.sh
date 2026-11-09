helm lint labapp >/dev/null
helm install web ./labapp -n t10 -f values-t10.yaml --wait --timeout 3m >/dev/null
helm upgrade web ./labapp -n t10 -f values-t10.yaml --set image.tag=1.4 --wait --timeout 3m >/dev/null
helm upgrade web ./labapp -n t10 -f values-t10.yaml --set image.tag=1.5 --wait --timeout 60s >/dev/null 2>&1 || true
helm rollback web 1 -n t10 --wait --timeout 3m >/dev/null
v=$(kx -n t10 get secret sh.helm.release.v1.web.v1 -o jsonpath='{.data.release}' | base64 -d | base64 -d | gunzip | jq -r .chart.metadata.version)
printf 'release_secrets: %s\nchart_version: %s\n' "$(kx -n t10 get secrets -l owner=helm,name=web --no-headers | wc -l)" "$v" > answers.yaml
