## Hint 1
CA hash: `openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl pkey -pubin -outform der |
openssl dgst -sha256 -hex | sed 's/^.* /sha256:/'`. A token: `kubeadm token create --ttl 1h`
(`kubeadm token list`).

## Hint 2
Without the node IP the kubelet picks the address of the default route - 10.0.2.15 on the NAT NIC, the same
on every VM: pod traffic, logs and exec break in strange ways. Either `nodeRegistration.kubeletExtraArgs`
`node-ip` in the JoinConfiguration, or `KUBELET_EXTRA_ARGS=--node-ip=192.168.56.33` in `/etc/default/kubelet`
before the join. Then `kubeadm join --config /root/join.yaml`.

## Hint 3
`kubectl get csr` shows a `kubernetes.io/kubelet-serving` request from `system:node:k8s-w3` in Pending:
`kubectl certificate approve <name>`. The cluster runs `serverTLSBootstrap: true`, so kubelets get real
serving certs that metrics-server can verify - and nobody auto-approves them.
`kubectl label node k8s-w3 topology.kubernetes.io/zone=zone-b`.
