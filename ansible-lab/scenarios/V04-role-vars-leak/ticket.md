# Shop unreachable on 8080 since the metrics role was added - it answers on 9100
**OPS-251** · P1 · Reporter: web on-call

The observability team added their `metrics` role to `site.yml` (see git log). Since then the shop no longer
listens on 8080 - it answers on 9100, next to the metrics endpoint. Nobody touched the `web` role.

**Test**: web1 serves the shop on 8080 and metrics on 9100; both roles pass ansible-lint's variable-naming rules;
site.yml converges.
