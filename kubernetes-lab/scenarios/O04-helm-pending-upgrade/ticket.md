# Can't upgrade the web release
**INC-2595** · P3 · Reporter: team helmx

Yesterday's CI job for release `web` (namespace `helmx`) was killed halfway through `helm upgrade --wait` (runner
OOM). Now every `helm upgrade` says *another operation (install/upgrade/rollback) is in progress*. Nobody is
running helm. Today's release is in `workspace/O04/values.yaml` (chart: `charts/labapp` in the lab directory):
`helm upgrade web charts/labapp -n helmx -f workspace/O04/values.yaml`.

**Test**: release `web` is `deployed` with today's values (the pods greet "Hallo", image `labapp:1.4`); `web` has 2
Ready pods; its current revision is deployed (no pending operation).
