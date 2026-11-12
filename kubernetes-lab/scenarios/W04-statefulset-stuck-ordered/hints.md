## Hint 1
`kubectl -n quorum describe pod quorum-0` - why isn't it Ready? Then: why does that stop `quorum-1` from being
created?

## Hint 2
With `podManagementPolicy: OrderedReady` the controller creates member N+1 only after member N is Running and
Ready. labapp's readiness endpoint is `/ready`; `/readyz` answers 404.

## Hint 3
Fix the probe path and apply. `quorum-0` was created from the broken template and isn't Ready, so the rolling
update won't replace it: `kubectl -n quorum delete pod quorum-0` once the template is fixed.
