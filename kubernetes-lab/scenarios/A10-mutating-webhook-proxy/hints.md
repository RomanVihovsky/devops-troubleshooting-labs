## Hint 1
Compare what you applied with what runs: `kubectl -n wallet get deploy wallet -o yaml` vs
`kubectl -n wallet get pod <new pod> -o yaml` - look at `env`. Who added the extra variables?
(`kubectl get mutatingwebhookconfigurations`)

## Hint 2
The webhook adds `HTTP_PROXY`/`HTTPS_PROXY` and nothing else. Every HTTP client then sends **all** requests -
including `http://ledger-api.wallet.svc:8080` - to the proxy, which can't (and shouldn't) reach cluster services.
Which variable tells clients what to reach directly?

## Hint 3
`NO_PROXY=.svc,.cluster.local,10.96.0.0/12,localhost` - either in egress-guard's patch (`WEBHOOK_PATCH` in its
Deployment: one more `add` operation, the fix for everyone) or in wallet's own env. Then the new pods come up.
