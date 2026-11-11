# L10 - a static pod nobody remembered

**Root cause**: `/etc/kubernetes/manifests/netdebug.yaml` on `k8s-w2`. The kubelet runs every manifest in its
`staticPodPath` and creates a read-only **mirror pod** in the API, named `<pod>-<node>`. Deleting the mirror
only makes the kubelet create it again; the pod itself never stopped.

**Diagnosis**
```
kubectl get pod netdebug-k8s-w2 -o jsonpath='{.metadata.ownerReferences}'; echo   # kind: Node
kubectl get pod netdebug-k8s-w2 -o jsonpath='{.metadata.annotations}'; echo       # kubernetes.io/config.source: file
./lab node w2
sudo grep staticPodPath /var/lib/kubelet/config.yaml
ls -l /etc/kubernetes/manifests
```

**Fix**: delete the file. The kubelet stops the container and removes the mirror pod.

**Interview notes**
- Static pods: kubeadm's control plane uses them on control-plane nodes. On workers the directory exists
  too and should be empty. A forgotten manifest there is a persistence mechanism: auditors look for them.
- Mirror pods have an owner reference to the Node and the `kubernetes.io/config.mirror` annotation. They
  can't be edited, and DaemonSet/Deployment logic doesn't apply.
- Don't "fix" it by clearing `staticPodPath`: on a control-plane node that stops the API server.
- With `hostNetwork: true` a debug pod sees all of the node's traffic. Admission (PSA `baseline` forbids it
  in namespaces) doesn't apply to static pods; they're created by the kubelet.
