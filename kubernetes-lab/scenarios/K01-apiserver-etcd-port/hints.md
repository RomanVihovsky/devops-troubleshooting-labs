## Hint 1
The API server is a **static pod**: kubelet runs it from `/etc/kubernetes/manifests/`. With the API down,
look on the node: `sudo crictl ps -a | grep kube-apiserver`, then `sudo crictl logs <id>`.

## Hint 2
The apiserver log keeps repeating a dial error to etcd. Which address and port does it dial? Which port does
etcd listen on (`/etc/kubernetes/manifests/etcd.yaml`, `--listen-client-urls`)?

## Hint 3
`--etcd-servers` in `/etc/kubernetes/manifests/kube-apiserver.yaml` says `:2397`; etcd serves clients on
**2379**. Fix the flag in the manifest - kubelet notices the change and recreates the pod (give it a
minute). Never edit a copy *inside* `manifests/`: kubelet runs every file in there.
