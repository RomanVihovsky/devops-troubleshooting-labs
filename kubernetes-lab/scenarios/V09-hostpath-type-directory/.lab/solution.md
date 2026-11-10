# V09 - hostPath type Directory, but the directory doesn't exist

**Root cause**: `hostPath.type: Directory` makes the kubelet check that the path exists and is a
directory; on fresh nodes it doesn't: `MountVolume.SetUp failed ... hostPath type check failed`, the pod
stays ContainerCreating.

**Fix**: `DirectoryOrCreate` (or create the directory with node provisioning).

**Interview notes**
- hostPath types: "" (no check), DirectoryOrCreate, Directory, FileOrCreate, File, Socket, CharDevice,
  BlockDevice. kubeadm uses them for the control-plane static pods.
- hostPath ties the pod to node state and is a security risk (PSA baseline forbids it) - fine for node
  agents, wrong for apps (use a PVC).
