## Hint 1
No events at all means nobody looked at the pod. Which component assigns pods to nodes? `kubectl -n
kube-system get pods -l component=kube-scheduler`.

## Hint 2
On k8s-cp1: `crictl ps -a | grep scheduler`, `crictl images | grep scheduler`, `journalctl -u kubelet |
grep -i scheduler` - what does the kubelet fail to do?

## Hint 3
Compare the image in `/etc/kubernetes/manifests/kube-scheduler.yaml` with the other control-plane
manifests (`registry.k8s.io/kube-scheduler:<version>`). Fix it; the kubelet restarts the pod by itself.
