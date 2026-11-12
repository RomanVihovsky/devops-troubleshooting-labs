# etl jobs can't start since the workers were "dedicated to batch"
**INC-2503** · P3 · Reporter: data team

The platform team dedicated all workers to batch workloads this morning. Our `etl` Deployment (namespace
`etl`, `workspace/S03/etl.yaml`) **is** a batch workload, but its pods stay **Pending**: *untolerated
taint*. The taints stay as they are.

**Test**: etl runs on the workers; the workers' taints are unchanged.
