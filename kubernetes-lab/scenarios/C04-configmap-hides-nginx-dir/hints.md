## Hint 1
`kubectl -n web logs deploy/web --previous` and `kubectl -n web get deploy web -o
jsonpath='{.spec.template.spec.containers[0].volumeMounts}'`. What lives in `/etc/nginx` in the image?

## Hint 2
A volume mounted on a directory **replaces** that directory's content in the container: `/etc/nginx` now
holds only `nginx.conf`.

## Hint 3
Mount just the one file: `mountPath: /etc/nginx/nginx.conf` with `subPath: nginx.conf` (fine here: nginx reads it
at start anyway). Apply and wait for the rollout.
