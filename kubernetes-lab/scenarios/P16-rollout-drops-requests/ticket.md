# Every deploy of checkout-api fails a few checkouts
**INC-2618** · P2 · Reporter: team checkout

Each time `checkout-api` is rolled out (`workspace/P16/checkout-api.yaml`), our synthetic checkout test sees a
burst of failed requests - connection refused, connection reset - for a few seconds per replaced pod. The
service is healthy before and after. Rolling updates are supposed to be zero-downtime; make them so.

**Test**: during a rollout restart under load (the test runs one: 8 concurrent clients calling
`/slow?ms=300` through the Service for 50 s) no request fails; `checkout-api` keeps 3 Ready replicas of labapp.
