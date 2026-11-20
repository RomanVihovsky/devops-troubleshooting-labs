# The storefront loses pods every time the batch runs
**INC-2640** · P2 · Reporter: team storefront

`storefront` runs 3 replicas on `k8s-w2` (the node with the local SSD cache). Whenever the platform team's
`nightly-batch` Job starts on the same node, one of our pods vanishes and its replacement stays *Pending* until
the batch is done. Nobody deletes anything - the events say *Preempted*. The batch can wait for room; the
storefront must not lose pods to it.

The batch uses the shared PriorityClass `batch-high` (`workspace/S10/priority.yaml`): other batch teams depend on
its priority **value**, and the Job itself must keep using it (`workspace/S10/nightly-batch.yaml`).

**Test**: the test starts a fresh run of the batch Job (unchanged, class `batch-high`): for 60 s no `storefront`
pod is preempted and all 3 stay Ready; `batch-high` keeps its value 1000000.
