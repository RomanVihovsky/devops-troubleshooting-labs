## Hint 1
`kubectl -n gw-shop get httproute shop -o yaml` (status.parents) and `kubectl -n gw-infra get gateway team -o yaml`
- look at the listener's `allowedRoutes`.

## Hint 2
`allowedRoutes.namespaces.from`: `Same` (only the Gateway's namespace), `All`, or `Selector` with a label
selector on **namespaces**. Does `gw-shop` carry the agreed label?

## Hint 3
On the Gateway: `allowedRoutes: {namespaces: {from: Selector, selector: {matchLabels: {gateway-access: team}}}}`;
and `kubectl label namespace gw-shop gateway-access=team`.
