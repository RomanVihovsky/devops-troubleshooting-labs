# G05 - a Gateway listener decides who may attach

**Root cause**: the listener's `allowedRoutes.namespaces.from: Same` admits only routes from `gw-infra`. The shop
team's route lives in `gw-shop`, so the Gateway refused it (`Accepted=False, NotAllowedByListeners`) and no
router was built for `shop.team.lab`.

**Diagnosis**
```
kubectl -n gw-shop get httproute shop -o jsonpath='{.status.parents}' | jq
kubectl -n gw-infra get gateway team -o jsonpath='{.spec.listeners[0].allowedRoutes}'; echo
kubectl get ns --show-labels | grep gw-
```

**Fix**: `from: Selector` with `matchLabels: {gateway-access: team}`, and label the approved namespace.

**Interview notes**
- Gateway API splits roles: the infra team owns `GatewayClass`/`Gateway` (listeners, certificates, who may
  attach), app teams own `HTTPRoute`s. `allowedRoutes` (namespaces + kinds) is the contract between them.
- Route status is per parent: always read `status.parents[].conditions` (Accepted, ResolvedRefs).
- `from: All` "fixes" it and lets any namespace publish any host on that listener (hijacking
  `admin.team.lab`). Use Selector + hostnames.
