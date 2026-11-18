## Hint 1
Two independent problems; fix access first. `./lab node cp1`, `openssl x509 -noout -dates -in
/etc/kubernetes/pki/apiserver.crt`. kubeadm can renew it - with the API down give it the local config
(`/etc/kubernetes/kubeadm/init.yaml`).

## Hint 2
`kubeadm certs renew apiserver --config /etc/kubernetes/kubeadm/init.yaml`, then restart the API server (change an
annotation in its manifest or `crictl stop` it). Then the restore: K06 / T08 - `etcdutl snapshot restore` into a new
data dir and point the `etcd-data` hostPath at it.

## Hint 3
After the restore the PVC and its PV come back from the snapshot as they were (Bound). The volume's class keeps
released volumes (`Retain`), so the NFS directory and its data were never deleted - ledger finds its data again. Two more
things: restart the kubelet on every node and the calico-node / kube-proxy DaemonSets (their watches stall on the
rewound store), and the restored ledger
**pod** is a ghost (the API says Running, its kubelet killed that pod long ago) - delete
it (or `rollout restart`) and the ReplicaSet starts a real one.
