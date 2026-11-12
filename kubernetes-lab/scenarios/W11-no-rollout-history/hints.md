## Hint 1
`kubectl -n pay rollout history deploy/checkout` and `kubectl -n pay get rs`. Where does `rollout undo` get the
previous version from?

## Hint 2
The previous revision is a scaled-down ReplicaSet - with `revisionHistoryLimit: 0` the controller deletes it as soon
as a rollout completes. The bad release *did* complete: its pods are Ready, they just fail every request.

## Hint 3
Roll forward to the old spec by hand: `kubectl -n pay set image deploy/checkout labapp=registry.lab:5000/lab/labapp:1.3`,
`kubectl -n pay set env deploy/checkout ERROR_RATE-`, and `kubectl -n pay patch deploy checkout -p
'{"spec":{"revisionHistoryLimit":10}}'`.
