# What happened to api overnight?
**PM-61** · P3 · Reporter: SRE lead

`api` (namespace `incident`) has been broken since a release overnight. Nobody was paged, and the events have
expired (`kubectl get events` is empty). Reconstruct the facts for the post-mortem into
`workspace/Q04/answers.yaml` from what Kubernetes still keeps. Don't fix or change anything.

**Test**: your answers match the cluster: the image that broke it, the last image that worked, the setting the
broken version complains about, and the exit code of the failing container.
