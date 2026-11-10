## Hint 1
`kubectl get nodes -o wide`: compare the INTERNAL-IP of the workers. Where does the API server connect to
for logs and exec?

## Hint 2
Every VM has a NAT NIC with the same address (10.0.2.15). Without an explicit node IP the kubelet resolves
its own hostname (`getent hosts k8s-w2`); a loopback answer such as cloud-init's `127.0.1.1` is skipped, and
it falls back to the address of its default route.

## Hint 3
Put `--node-ip=192.168.56.32` back into `KUBELET_KUBEADM_ARGS` in `/var/lib/kubelet/kubeadm-flags.env`
(compare with k8s-w1), `systemctl restart kubelet`. An explicit node IP doesn't depend on `/etc/hosts`.
