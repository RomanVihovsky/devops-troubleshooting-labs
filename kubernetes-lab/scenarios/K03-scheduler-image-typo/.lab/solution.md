# K03 - no scheduler, no events

**Root cause**: the scheduler manifest points at `registry.k8s.io/kube-schedular:<version>` - the image
doesn't exist, the static pod never starts. Without a scheduler nobody sets `spec.nodeName`: pods stay
Pending and, because only the scheduler writes FailedScheduling events, there are **no events**.

**Diagnosis**: `kubectl -n kube-system get pods` (scheduler missing or ImagePullBackOff), on cp1 `crictl
ps -a`, `journalctl -u kubelet | grep schedular`.

**Fix**: correct the image in the manifest; the kubelet restarts the static pod.

**Interview notes**
- "Pending without events" → scheduler down, or `spec.schedulerName` names a scheduler that doesn't exist
  (S07). "Pending with FailedScheduling" → the scheduler ran and said why.
- Static pod images come from the manifest (written by kubeadm from `imageRepository` + version) - an
  upgrade or an "image cleanup" edits them directly.
- `kubectl get --raw /livez?verbose` covers the API server; scheduler and controller-manager health is
  their `/healthz` (ports 10259/10257) or simply their pods' Ready state.
