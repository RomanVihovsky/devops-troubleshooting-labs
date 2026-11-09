# Orders frontend: "upstream timeout", backend pods are healthy
**INC-1042** · P2 · Reporter: on-call (orders team)

Since this morning's "label cleanup" release, `http://frontend.orders/upstream` answers **502** - the
frontend can't reach `http://backend/items`. Both Deployments in namespace `orders` are `2/2` Ready,
nothing restarts, and the backend pods answer fine when you hit their pod IPs directly.
The manifests as deployed are in `workspace/N01/`.

**Test**: the frontend gets 200 from the backend through the `backend` Service, and the backend pods keep
their labels (other tooling selects on them).
