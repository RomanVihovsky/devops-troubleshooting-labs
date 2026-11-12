## Hint 1
No pods means the ReplicaSet couldn't create them: `kubectl -n team-b describe rs -l app=worker` (Events).

## Hint 2
`kubectl -n team-b describe limitrange` - admission rejects pods outside the min/max of a LimitRange.

## Hint 3
Set the container's CPU request (and limit) within the range, e.g. `kubectl -n team-b set resources deploy/worker
--requests=cpu=200m --limits=cpu=500m`.
