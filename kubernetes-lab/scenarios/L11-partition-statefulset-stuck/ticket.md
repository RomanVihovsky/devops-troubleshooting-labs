# inventory DB down: db-0 stuck Terminating since k8s-w3 died
**INC-2320** · P1 · Reporter: on-call

k8s-w3 dropped off the network 10 minutes ago (the hardware team is on it - **leave the node alone**). The
`web` pods of namespace `inventory` were replaced on other nodes, but the database pod `db-0` (StatefulSet
`db`, data on NFS) shows **Terminating** and no new `db-0` appears. The data must survive.

**Test**: `db-0` runs and is Ready on another node, with the same volume and its data (`/data/orders.db`);
`web` has 2 ready pods away from k8s-w3; the StatefulSet still has 1 replica.
