## Hint 1
`kubectl -n reports get pods` - how many containers does the pod have, and which of them are still running?
A Job is complete when its **pod** succeeds, and a pod succeeds only when all its containers have exited.

## Hint 2
`labapp ship-logs` follows the file forever, like any log shipper. Kubernetes has a container type for helpers
that should run alongside the main container and be stopped when it is done: the **native sidecar** (an init
container with `restartPolicy: Always`, GA since 1.33).

## Hint 3
Move `shipper` from `containers` to `initContainers` and give it `restartPolicy: Always`. A Job's pod template is
immutable: `kubectl -n reports delete job nightly-report`, then apply the edited file.
