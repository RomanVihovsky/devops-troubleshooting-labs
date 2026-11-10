## Hint 1
`kubectl get nodes --show-labels | grep -i ssd` (or `kubectl get nodes -L disk,disktype`).

## Hint 2
Compare the label **key** in the pod's `nodeSelector` with the key on the node.

## Hint 3
`nodeSelector: {disk: ssd}` in `indexer.yaml`, apply.
