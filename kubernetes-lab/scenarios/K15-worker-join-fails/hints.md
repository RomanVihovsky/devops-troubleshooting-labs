## Hint 1
Run the wiki command on `k8s-w3` (`./lab node w3`, `sudo`) with `-v=5`: which step fails, and why? Compare the
token with `sudo kubeadm token list` on `k8s-cp1`, and the hash with the cluster's CA:
`openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl pkey -pubin -outform der | sha256sum`.

## Hint 2
Both parts are stale: the token expired (bootstrap tokens have a TTL; expired ones are deleted), and the hash
is of another CA. `sudo kubeadm token create --print-join-command` on cp1 prints a fresh, complete command.
On VirtualBox the kubelet also needs `--node-ip` (both VMs' NAT NICs are 10.0.2.15) - see learn lab T03.

## Hint 3
On w3: `echo 'KUBELET_EXTRA_ARGS=--node-ip=192.168.56.33' | sudo tee /etc/default/kubelet`, then the fresh join
command. Afterwards on the desktop: approve w3's serving CSR (`kubectl get csr`, `kubectl certificate approve`)
and `kubectl label node k8s-w3 topology.kubernetes.io/zone=zone-b`.
