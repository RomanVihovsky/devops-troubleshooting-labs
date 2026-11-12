# k8s-w3 can't rejoin after its rebuild
**INC-2396** · P2 · Reporter: platform team

`k8s-w3` was wiped (`kubeadm reset`) and removed from the cluster for a disk swap. The engineer copied the join
command from our wiki ("Adding workers", `workspace/K15/join-command.txt`) and ran it on `k8s-w3`: it fails at
discovery. Join it back properly: same node name, its host-only address, zone label `zone-b`, `kubectl logs`
must work for its pods. And don't leave a join token that never expires lying around.

**Test**: `k8s-w3` Ready with InternalIP `192.168.56.33` and label `topology.kubernetes.io/zone=zone-b`;
`kubectl logs` works for a pod on it; kubelet enabled; `kubeadm token list` shows no token without expiry.
