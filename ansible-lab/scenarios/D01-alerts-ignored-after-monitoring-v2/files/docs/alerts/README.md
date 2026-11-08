# Alert payloads (from the monitoring team)

* `v1-*.json` - Monitoring 1.x (retired 2026-11-04).
* `v2-*.json` - Monitoring 2.0, live since 2026-11-04: one envelope per alert, states `ok` / `warning` /
  `critical`, targets by FQDN. Sent as `POST application/json` to the EDA webhook, re-sent every 5 minutes
  while the state is not `ok`.
