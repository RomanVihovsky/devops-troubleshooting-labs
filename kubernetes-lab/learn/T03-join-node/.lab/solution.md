# T03 - solution and takeaways

```
# k8s-cp1
kubeadm token create --ttl 1h
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl pkey -pubin -outform der \
  | openssl dgst -sha256 -hex | sed 's/^.* /sha256:/'
# k8s-w3: join.yaml with the token, the hash and
#   nodeRegistration.kubeletExtraArgs: [{name: node-ip, value: 192.168.56.33}]
kubeadm join --config /root/join.yaml
# desktop
kubectl get csr | grep Pending; kubectl certificate approve <csr>
kubectl label node k8s-w3 topology.kubernetes.io/zone=zone-b
```

**Takeaways**
- Discovery = token (authenticates the node to the API, short-lived) + CA hash (authenticates the API to
  the node: without it, a man in the middle could hand out its own CA).
- TLS bootstrap: the kubelet uses the bootstrap token once to request its **client** certificate (CSR,
  auto-approved by the controller-manager) and writes `/etc/kubernetes/kubelet.conf`. With
  `serverTLSBootstrap: true` it also requests a **serving** certificate - which is **not** auto-approved.
  Symptom: node Ready, but `kubectl logs/exec` and metrics fail for it ("tls: internal error").
- Multi-NIC VMs (VirtualBox NAT, cloud VMs with several interfaces): always pin `--node-ip`. The wrong
  INTERNAL-IP breaks logs/exec, NodePorts and sometimes the CNI.
- Clean removal: `drain` -> `delete node` -> `kubeadm reset` on the node (+ CNI config and iptables), in
  that order.
