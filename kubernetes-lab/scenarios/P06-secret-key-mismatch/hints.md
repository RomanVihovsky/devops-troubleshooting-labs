## Hint 1
`kubectl -n ledger describe pod <pod>` - the event names the Secret *and* the key.

## Hint 2
`kubectl -n ledger get secret ledger-db -o jsonpath='{.data}'` - which keys does it really have?

## Hint 3
Point `secretKeyRef.key` at the key that exists (`passwd`) in `ledger.yaml`, apply.
