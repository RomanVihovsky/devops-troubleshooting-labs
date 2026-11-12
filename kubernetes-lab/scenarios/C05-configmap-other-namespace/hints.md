## Hint 1
`kubectl get configmap app-config -o jsonpath='{.metadata.namespace}'` - and in which namespace does the pod
look? (`kubectl config view --minify | grep namespace`)

## Hint 2
ConfigMaps (and Secrets) are namespaced, and a pod can only reference ones in its own namespace. The runbook's
file has no `namespace:` - it went to the namespace of the current context.

## Hint 3
`kubectl -n checkout apply -f workspace/C05/app-config.yaml` (and delete the stray one in `default`). The kubelet
retries the pods by itself.
