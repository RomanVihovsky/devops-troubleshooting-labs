# Post-mortem: what restarted the reporting pod?
**PM-58** · P4 · Reporter: SRE lead

The `reporting` pod (namespace `nightly`) shows one restart from the nightly run. Before we change anything, the
post-mortem needs the facts. Fill in `workspace/Q02/answers.yaml`. Don't change the workload.

**Test**: your answers match the cluster: which container restarted, the reason Kubernetes recorded, its exit code,
and that container's memory limit.
