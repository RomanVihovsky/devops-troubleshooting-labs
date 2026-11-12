## Hint 1
`openssl s_client -connect 192.168.56.20:6443 </dev/null 2>/dev/null | openssl x509 -noout -ext subjectAltName`
from the desktop. On cp1 (`./lab node cp1`), use the endpoint the nodes use:
`sudo kubectl --kubeconfig /etc/kubernetes/admin.conf -n kube-system get cm kubeadm-config -o yaml`.

## Hint 2
kubeadm always puts the node name, the advertise address, the service IP and the `controlPlaneEndpoint`
host into the certificate. Extra names and IPs come only from `apiServer.certSANs` - which the tidy-up
removed. The load balancer's IP (192.168.56.20) was one of them.

## Hint 3
Put `certSANs: [k8s-api.lab, 192.168.56.20, k8s-cp1, 192.168.56.21]` back under `apiServer:` in the
ConfigMap, write the ClusterConfiguration + `/etc/kubernetes/kubeadm/init.yaml`'s InitConfiguration into one
file, `sudo rm /etc/kubernetes/pki/apiserver.{crt,key}`, `sudo kubeadm init phase certs apiserver --config
<file>`, then make the kubelet restart the API server (change the manifest, e.g. an annotation; `crictl stop` works too but is subject to the restart back-off).
