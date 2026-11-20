# Security audit: every monitoring pod can reach the orders database
**INC-2671** · P2 · Reporter: security

The audit found that `orders-db` (namespace `db`, port 5432) accepts connections from **any** pod in namespace
`monitoring`, and even from pods in `db` that merely carry the label `app: prometheus`. The intent of
`workspace/X05/allow-prometheus.yaml` was: only the Prometheus pods (`app: prometheus`) **in** namespace
`monitoring` may connect. Make the policy say what it means.

**Test**: Prometheus pods in `monitoring` connect to `orders-db.db.svc:5432`; other pods in `monitoring` don't;
pods labelled `app: prometheus` in `db` don't; a NetworkPolicy still protects `orders-db`.
