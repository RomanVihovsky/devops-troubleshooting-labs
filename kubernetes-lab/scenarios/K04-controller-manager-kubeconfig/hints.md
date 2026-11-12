## Hint 1
Who turns a Deployment into a ReplicaSet and a ReplicaSet into pods? `kubectl -n kube-system get pods -l
component=kube-controller-manager`.

## Hint 2
On k8s-cp1: `crictl ps -a | grep controller-manager`, `crictl logs <id>` - which file can't it open?

## Hint 3
`--kubeconfig` in `/etc/kubernetes/manifests/kube-controller-manager.yaml` must name the file that exists
**and** is mounted into the pod: `/etc/kubernetes/controller-manager.conf` (see the volumes section).
