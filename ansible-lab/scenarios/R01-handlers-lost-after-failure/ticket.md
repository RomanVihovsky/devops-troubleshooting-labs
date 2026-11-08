# Shop 2.4.1 deploy fails at the smoke check - re-running doesn't help
**OPS-284** · P2 · Reporter: release manager

Yesterday we added a smoke check to the deploy (see `git log`) and released 2.4.1. The deploy fails:
`Smoke: the new version is live` gets `2.4.0`. The template task says the vhost is already at 2.4.1, yet web1
keeps serving 2.4.0 - and every re-run fails the same way.

**Test**: web1:8080 serves 2.4.1; site.yml runs green and converges; a future release (any new `shop_version`)
goes live and passes the smoke check **in a single run**.
