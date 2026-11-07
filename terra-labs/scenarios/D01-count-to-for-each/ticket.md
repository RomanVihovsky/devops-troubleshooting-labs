# Refactor PR wants to recreate all 6 web containers
**INFRA-163** · P2 · Reporter: web platform

PR "web: for_each over sites" is approved: with `count`, removing one site renumbers all the others.
But `terraform plan` on `web/` now wants to **destroy and recreate all six frontends**
(`tfl-web-eu-1` ... `tfl-web-ap-2`) - that is a full outage, not a refactor.

Keep the `for_each` version. Not a single container may be recreated.

**Test**: state is keyed by site name; all six containers are the same ones as before (not recreated);
a CI plan shows no changes.
