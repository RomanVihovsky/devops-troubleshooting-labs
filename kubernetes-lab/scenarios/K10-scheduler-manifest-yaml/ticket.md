# New pods Pending, and there is no scheduler pod
**INC-2388** · P1 · Reporter: on-call

New pods stay *Pending* with no events. `kubectl -n kube-system get pods` lists etcd, the API server and the
controller-manager, but **no kube-scheduler** - not crashing, simply gone. A colleague raised the scheduler's
log level on `k8s-cp1` an hour ago (`--v=2`, we need that for a support case - keep it).

**Test**: the kube-scheduler mirror pod is Ready and runs with `--v=2`; the waiting pods in `ops` are Running;
the scheduler manifest is valid YAML; only the 4 control-plane manifests are in `/etc/kubernetes/manifests`.
