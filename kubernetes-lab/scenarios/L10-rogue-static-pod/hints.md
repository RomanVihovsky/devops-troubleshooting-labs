## Hint 1
`kubectl get pod netdebug-k8s-w2 -o yaml`: look at `metadata.ownerReferences` and the annotations. Which
object "owns" it?

## Hint 2
It's a **mirror pod** of a static pod: the kubelet on `k8s-w2` runs it from a file and mirrors it into the
API. Deleting the mirror changes nothing. `staticPodPath` in `/var/lib/kubelet/config.yaml` tells you where.

## Hint 3
`./lab node w2`, `ls /etc/kubernetes/manifests`, remove the file (`sudo rm ...`). The kubelet stops the pod
and deletes the mirror within seconds.
