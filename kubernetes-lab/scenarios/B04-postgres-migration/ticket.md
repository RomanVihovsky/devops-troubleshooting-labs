# orders' new in-cluster Postgres: nothing works
**INC-2930** · P1 · Reporter: team orders

We moved `orders`' database into the cluster (namespace `orders-db`, `workspace/B04/postgres.yaml` - written from the
production Helm chart's output, by hand). `postgres-0` never starts and `orders` is NotReady. The app connects to
`postgres-0.postgres.orders-db.svc` (the primary, by name - replicas will follow). The DBA created Secret
`postgres-auth` and says it is correct. The data must live on a persistent volume of this cluster.

**Test**: `postgres-0` is Ready on a Bound PVC `data-postgres-0`; `postgres-0.postgres.orders-db.svc` resolves to it;
`orders` is Ready (connected, schema migrated) and serves its items - also after `postgres-0` is deleted and comes back.
