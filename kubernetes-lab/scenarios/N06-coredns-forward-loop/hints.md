## Hint 1
`kubectl -n kube-system logs -l k8s-app=kube-dns --previous` - what does CoreDNS detect before it exits?

## Hint 2
`forward . 127.0.0.1`: inside the CoreDNS pod, 127.0.0.1 is CoreDNS itself. The `loop` plugin notices
the query coming back and stops the server.

## Hint 3
`forward . /etc/resolv.conf` (the node's resolver, the kubeadm default) in the Corefile; CoreDNS reloads
the ConfigMap by itself (`reload` plugin), or `kubectl -n kube-system rollout restart deploy/coredns`.
