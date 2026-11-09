## Hint 1
`systemctl cat kubelet` on k8s-w1: the drop-in `10-kubeadm.conf` sources `EnvironmentFile`s - one written
by kubeadm (`KUBELET_KUBEADM_ARGS`), one for you (`KUBELET_EXTRA_ARGS`). `grep -E 'cgroupDriver|staticPodPath'
/var/lib/kubelet/config.yaml`.

## Hint 2
`grep server: /etc/kubernetes/kubelet.conf` - it is the kubeadm `controlPlaneEndpoint`, not the IP of
k8s-cp1. Since Kubernetes 1.29, admin.conf is not `system:masters` any more but a group bound to
cluster-admin by a ClusterRoleBinding (`kubectl get clusterrolebinding kubeadm:cluster-admins -o yaml`).

## Hint 3
`grep -- --data-dir /etc/kubernetes/manifests/etcd.yaml`; `openssl x509 -enddate -noout -in
/etc/kubernetes/pki/ca.crt` (the CA lives 10 years, the leaf certs 1 year); the service CIDR is
`networking.serviceSubnet` in kubeadm-config.
