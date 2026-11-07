# Fresh environments fail randomly: "network tfl-jobs-net not found"
**INFRA-229** · P3 · Reporter: CI (ephemeral review environments)

Review environments spin up `stacks/worker` from scratch. About one run in three fails with
`Error: Unable to create container: ... network tfl-jobs-net not found`. Re-running the apply always
works, so people just click retry. Existing environments are fine.

Make a from-scratch apply deterministic. Don't recreate the existing containers.

**Test**: Terraform's graph orders the containers after the network; the existing worker containers
were not recreated; a CI plan shows no changes.
