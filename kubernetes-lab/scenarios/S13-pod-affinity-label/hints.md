## Hint 1
`kubectl -n sessions describe pod -l app=session-api` (Events), then `kubectl -n sessions get pods --show-labels`.

## Hint 2
Pod affinity selects **pods** by label (in the same namespace unless `namespaces`/`namespaceSelector` say
otherwise). Which label does the rule ask for, and which one does the cache pod carry?

## Hint 3
`matchLabels: {app: redis-cache}` in the affinity term, apply.
