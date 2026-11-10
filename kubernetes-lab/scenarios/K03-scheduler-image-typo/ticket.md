# new pods never start - no events at all
**INC-2295** · P2 · Reporter: ops team

Since this morning's control-plane "image cleanup", every new pod stays **Pending**, and `kubectl describe
pod` shows **no events** - not even "FailedScheduling". Existing pods keep running. The `batch` Deployment
in namespace `ops` is the first victim.

**Test**: the kube-scheduler static pod runs its correct image and is Ready; `ops/batch` has 2 Running
pods; only the 4 control-plane manifests in `/etc/kubernetes/manifests`.
