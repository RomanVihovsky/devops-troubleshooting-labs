## Hint 1
`kubectl -n notify get secret api-token -o jsonpath='{.data.token}' | base64 -d` vs what notifier sends. How
does each Deployment get the token? Compare `workspace/Y07/upstream.yaml` and `workspace/Y07/notifier.yaml`.

## Hint 2
An environment variable is resolved once, when the container starts. A mounted Secret volume is updated by the
kubelet in place (not with `subPath`), and labapp re-reads `<SETTING>_FILE` on every use.

## Hint 3
In `notifier.yaml`: drop the `UPSTREAM_TOKEN` env var, mount Secret `api-token` (e.g. at `/etc/notify`, no
subPath) and set `UPSTREAM_TOKEN_FILE=/etc/notify/token`. `kubectl apply -f workspace/Y07/notifier.yaml`.
