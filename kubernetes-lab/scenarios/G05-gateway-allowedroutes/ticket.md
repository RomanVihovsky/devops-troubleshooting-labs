# The team gateway doesn't route shop.team.lab
**INC-2556** · P2 · Reporter: team shop

The platform team gave the teams their own Gateway `gw-infra/team` (listener for `*.team.lab`). Our HTTPRoute in
namespace `gw-shop` (`workspace/G05/route.yaml`) is *Accepted: False, NotAllowedByListeners*, and
`shop.team.lab` gives 404. Platform policy: only namespaces labelled `gateway-access: team` may attach routes to
that Gateway - `gw-shop` is approved, others (like `gw-other`) are not.

**Test**: the route is Accepted and `shop.team.lab` answers 200 through the LB; the Gateway admits routes by the
namespace label `gateway-access: team` (not from `All` namespaces), so a route from `gw-other` is still refused.
