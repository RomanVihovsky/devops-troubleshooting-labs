# Unknown "netdebug" pod in default - delete doesn't stick
**SEC-121** · P3 · Reporter: security

A pod `netdebug-k8s-w2` runs in `default` with `hostNetwork: true` and nobody owns it: no Deployment, no
Job, no DaemonSet. `kubectl delete pod` "works", and a few seconds later it's back. A contractor did network
debugging on `k8s-w2` last month. Get rid of it for good - without switching off anything the node needs.

**Test**: no `netdebug-*` pod for 60 s; nothing left of it on `k8s-w2` (its container is gone); the kubelet
on `k8s-w2` still reads static pods from `/etc/kubernetes/manifests` (its config is unchanged); `k8s-w2` Ready.
