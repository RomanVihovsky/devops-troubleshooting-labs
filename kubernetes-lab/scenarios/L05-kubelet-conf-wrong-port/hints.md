## Hint 1
`journalctl -u kubelet -n 30` on k8s-w1: what does it fail to connect to?

## Hint 2
`grep server: /etc/kubernetes/kubelet.conf` on k8s-w1 and on k8s-w2. The endpoint is haproxy on k8s-gw.

## Hint 3
Fix the server URL in `/etc/kubernetes/kubelet.conf` (`https://k8s-api.lab:6443`), `systemctl restart kubelet`.
