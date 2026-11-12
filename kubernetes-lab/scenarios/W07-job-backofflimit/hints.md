## Hint 1
`kubectl -n batch describe job nightly-report`, then the logs of one of its pods:
`kubectl -n batch logs -l job-name=nightly-report --tail=5`.

## Hint 2
Compare the path in the Job's `command` with the volume's `mountPath`.

## Hint 3
A Job's pod template can't be changed after creation: fix `report.yaml`, `kubectl -n batch delete job
nightly-report`, `kubectl apply -f workspace/W07/report.yaml`.
