# CI deploy: "provided hosts list is empty" - since the runner change
**OPS-219** · P2 · Reporter: CI

Since the runner team "fixed permission problems" in `ci/deploy.sh`, every CI deploy prints
`[WARNING]: No inventory was parsed, only implicit localhost is available` and deploys nothing - while the
very same `ansible-playbook site.yml` works on everyone's laptop.

**Test**: `CI_JOB_ID=<n> ci/deploy.sh` on a fresh checkout deploys both web nodes (the job ID lands in
`/etc/acme/deploy-id`); the CI build directory is not world-writable.
