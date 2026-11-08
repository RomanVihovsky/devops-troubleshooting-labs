# Role CI red: "Idempotence test failed because of the following tasks: node_report : Node report"
**OPS-333** · P3 · Reporter: platform team

The `node_report` role got molecule tests (`ci/molecule.sh`). Converge and verify are fine, idempotence fails -
every run rewrites `/etc/acme/node-report.txt`. The CMDB scraper only needs the fields that are in the report.

**Test**: `ci/molecule.sh` passes; the report task still reports a change when the facts behind it change
(no `changed_when`/`check_mode` tricks); molecule still catches a non-idempotent task.
