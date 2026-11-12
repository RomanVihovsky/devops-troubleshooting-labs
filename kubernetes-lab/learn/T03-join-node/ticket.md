# T03 · Join a node by hand: token, CA hash, node IP, serving CSR, labels
**Learn** · `kubeadm join` without the build script, and the traps of a two-NIC VM · ~30 min

`k8s-w3` was removed the clean way: `kubectl drain`, `kubectl delete node`, `kubeadm reset` on the node.
Bring it back as a worker by hand - the way you would add a new node to someone else's cluster.

1. On k8s-cp1 (`./lab node cp1`, `sudo -i`): create a bootstrap **token** (`kubeadm token create`) and work
   out the **CA public key hash** for `--discovery-token-ca-cert-hash` with openssl (or let
   `kubeadm token create --print-join-command` do both - but know what it does).
2. On k8s-w3: join through the API endpoint `k8s-api.lab:6443`. Every VM has a NAT NIC with the same
   address 10.0.2.15 - the kubelet must register with its **host-only IP 192.168.56.33**. A starter
   JoinConfiguration is in `workspace/T03/join.yaml`
   (copy it over: `./lab node w3 sudo tee /root/join.yaml < workspace/T03/join.yaml`).
3. `kubectl get nodes -o wide`: Ready, and the INTERNAL-IP right?
4. The kubelet asks for a **serving certificate** (`kubectl get csr`). Until it is approved, `kubectl logs`
   and `kubectl exec` fail for every pod on the node - try it, then approve it.
5. Label the node `topology.kubernetes.io/zone=zone-b`, like before.

**Test**: k8s-w3 is Ready with InternalIP 192.168.56.33 and zone `zone-b`, `kubectl logs` works for its
pods, and its kubelet is enabled.
