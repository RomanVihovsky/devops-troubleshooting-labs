## Hint 1
`./lab node cp1`, `sudo ls /var/log/kubernetes/audit/`, `sudo cat /etc/kubernetes/audit/policy.yaml`. Each line of the
log is one JSON event.

## Hint 2
Filter with jq: `sudo jq -c 'select(.objectRef.resource=="secrets" and .objectRef.namespace=="payments" and
.objectRef.name=="api-key" and (.verb=="get" or .verb=="list" or .verb=="watch"))' audit.log` - then look at
`.user`. List calls have no `objectRef.name`: check `list` on the namespace too.

## Hint 3
A ServiceAccount token issued to a pod carries the pod in `.user.extra["authentication.kubernetes.io/pod-name"]`.
Ignore the API server's and controllers' own requests (`system:` users that aren't ServiceAccounts in workload
namespaces).
