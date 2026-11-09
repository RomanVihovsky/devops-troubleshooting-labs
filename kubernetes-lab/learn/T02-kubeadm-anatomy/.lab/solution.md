# T02 - solution and takeaways

```
cgroup_driver: systemd                                  /var/lib/kubelet/config.yaml
static_pod_path: /etc/kubernetes/manifests              /var/lib/kubelet/config.yaml
node_ip_file: /var/lib/kubelet/kubeadm-flags.env        written by kubeadm from kubeletExtraArgs
kubelet_server: https://k8s-api.lab:6443                controlPlaneEndpoint (haproxy on k8s-gw)
admin_group: kubeadm:cluster-admins                     ClusterRoleBinding kubeadm:cluster-admins
etcd_data_dir: /var/lib/etcd
ca_expiry_year: <10 years after the build>              openssl x509 -enddate -in /etc/kubernetes/pki/ca.crt
service_cidr: 10.96.0.0/12                              kubeadm-config networking.serviceSubnet
```

**Takeaways - where the K/L incidents live**
- kubelet = systemd unit + drop-in `10-kubeadm.conf` + `config.yaml` (KubeletConfiguration) +
  `kubeadm-flags.env` (kubeadm's flags) + `/etc/default/kubelet` (`KUBELET_EXTRA_ARGS`, yours). A broken
  kubelet is almost always one of these five files, or the container runtime underneath.
- The control plane is 4 static pods: kubelet runs every file in `staticPodPath`, no API involved. A typo
  in a manifest = the component is gone, `kubectl` may be gone with it: debug with `crictl ps -a`,
  `crictl logs`, `journalctl -u kubelet`.
- PKI: CA 10 years, leaf certificates 1 year (`kubeadm certs check-expiration`, `kubeadm certs renew`;
  `kubeadm upgrade` renews them too). `super-admin.conf` (system:masters) exists for break-glass only.
- `kubeadm-config` is what `kubeadm upgrade` and `join` read: change the cluster with kubeadm, and keep this
  ConfigMap in line with what the static pod manifests really say.
