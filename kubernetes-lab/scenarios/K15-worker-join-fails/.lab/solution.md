# K15 - a stale join command

**Root cause**: the wiki's join command was stale in both parts:
- the **bootstrap token** had expired; the token cleaner deletes expired token Secrets
  (`kube-system/bootstrap-token-<id>`), so the API knew nothing about it;
- the **CA hash** belonged to a CA from before the cluster's PKI was rebuilt. Discovery pins the cluster CA
  by this hash: it downloads `kube-public/cluster-info` and refuses a CA whose public key doesn't match.

Plus the VirtualBox trap from T03: without `--node-ip`, the kubelet registers the NAT address 10.0.2.15,
which every VM shares.

**Diagnosis**
```
sudo kubeadm join ... -v=5               # on w3: which discovery step fails
sudo kubeadm token list                  # on cp1: the token is not there
openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl pkey -pubin -outform der | sha256sum   # the real hash
```

**Fix**
```
# cp1
sudo kubeadm token create --print-join-command     # fresh token (24 h TTL) + the right hash
# w3
echo 'KUBELET_EXTRA_ARGS=--node-ip=192.168.56.33' | sudo tee /etc/default/kubelet
sudo kubeadm join k8s-api.lab:6443 --token <new> --discovery-token-ca-cert-hash sha256:<hash>
# desktop
kubectl get csr | grep Pending; kubectl certificate approve <w3's kubelet-serving CSR>
kubectl label node k8s-w3 topology.kubernetes.io/zone=zone-b
```

**Interview notes**
- Join = discovery (trust the cluster: token + CA pin) + TLS bootstrap (the kubelet gets its client cert via
  a CSR, auto-approved for bootstrap tokens). With `serverTLSBootstrap` the **serving** cert CSR needs an
  approver: without it `kubectl logs/exec` fail with a TLS error.
- Never put join commands on wikis. Tokens live 24 h by default, and `--ttl 0` (no expiry) is a standing
  credential that lets anyone join a node. Generate the command when you need it.
- `--discovery-token-unsafe-skip-ca-verification` removes the CA pinning: a man in the middle can then
  hand the node a fake cluster.
- Rejoining under the same name: delete the old Node object first, or the new kubelet inherits its labels,
  taints and stale status.
