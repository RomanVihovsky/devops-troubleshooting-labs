## Hint 1
`kubectl get ns old-team -o jsonpath='{.status.conditions}' | jq` - the namespace controller says what it waits for.

## Hint 2
It can't delete the remaining objects because they have **finalizers**, and the controller that would remove
them (the backup operator) is gone. `kubectl -n old-team get backups -o yaml | grep -A2 finalizers`.

## Hint 3
`kubectl -n old-team patch backup <name> --type merge -p '{"metadata":{"finalizers":null}}'` for each one. The
namespace finishes by itself.
