# API server down after the security hardening
**INC-2290** · P1 · Reporter: platform team

The security team applied the CIS "hardening" to `/etc/kubernetes/manifests/kube-apiserver.yaml` on k8s-cp1
an hour ago: profiling off, an extra admission plugin, the serving cert "moved to the new naming
scheme", and a label for their inventory. Since then `kubectl` gets *connection refused*. Keep what is
valid of the hardening; undo only what is broken. Workloads are still serving.

**Test**: the API answers; the kube-apiserver static pod runs and has its mirror pod; `--profiling=false`
is still set; only valid admission plugins; the serving cert flags point at files that exist; only the 4
control-plane manifests in `/etc/kubernetes/manifests`.
