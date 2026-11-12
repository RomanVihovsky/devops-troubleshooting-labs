# legacy-sync stuck Pending, "pinned to w4 like in the runbook"
**INC-2508** · P3 · Reporter: integration team

`legacy-sync` (namespace `legacy`, `workspace/S08/legacy-sync.yaml`) is pinned to node `k8s-w4` "as the
runbook says". It stays **Pending** with no scheduling events. k8s-w4 is a spare VM that was never added
to this cluster. Any worker will do.

**Test**: legacy-sync runs and is Ready on a worker of this cluster.
