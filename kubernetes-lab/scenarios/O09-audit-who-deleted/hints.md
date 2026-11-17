## Hint 1
`./lab node cp1`; the log is `/var/log/kubernetes/audit/audit.log`, one JSON event per line. `jq` is your friend.

## Hint 2
`sudo jq -c 'select(.verb=="delete" and .objectRef.resource=="configmaps" and .objectRef.namespace=="checkout")
| {t: .requestReceivedTimestamp, user: .user.username, name: .objectRef.name, ua: .userAgent, code: .responseStatus.code}'
/var/log/kubernetes/audit/audit.log` - more than one delete happened; which one hit `feature-flags`, and did it
succeed?

## Hint 3
A failed attempt has `responseStatus.code` 403/404. The user agent of `kubectl` starts with `kubectl/`, of Helm
with `Helm/`. Then `kubectl apply -f feature-flags.yaml`.
