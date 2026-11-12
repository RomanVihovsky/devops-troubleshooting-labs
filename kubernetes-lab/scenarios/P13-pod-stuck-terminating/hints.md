## Hint 1
`kubectl -n queue get pod <old> -o jsonpath='{.metadata.deletionTimestamp} {.metadata.deletionGracePeriodSeconds}
{.metadata.finalizers}'`. Two things can keep a deleted pod: its grace period (the container still runs) and
finalizers (the object stays until they're gone).

## Hint 2
The app ignores SIGTERM (`SHUTDOWN_MODE=ignore`) and has 600 s to stop; a finalizer `example.com/cleanup` has no
controller left to remove it. `kubectl -n queue logs <old>`.

## Hint 3
Fix the Deployment first (`SHUTDOWN_MODE=graceful`, `terminationGracePeriodSeconds: 30`, apply) - the pods it
replaces still have the old 600 s, so they'll hang too. Then for every old pod: remove the finalizer
(`kubectl -n queue patch pod <p> --type json -p '[{"op":"remove","path":"/metadata/finalizers"}]'`) and, since it
ignores SIGTERM, `kubectl -n queue delete pod <p> --grace-period=0 --force`.
