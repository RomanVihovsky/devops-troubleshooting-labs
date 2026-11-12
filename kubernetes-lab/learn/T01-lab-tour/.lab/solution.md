# T01 - solution and takeaways

```
containerd_version_w2: 2.4.2       kubectl get nodes -o wide
zone_w3: zone-b                     kubectl get nodes -L topology.kubernetes.io/zone
argocd_ip: 192.168.56.201           kubectl -n argocd get svc argocd-server
api_backend: 192.168.56.21:6443     ./lab node gw; grep server /etc/haproxy/haproxy.cfg
default_storageclass: local-path    kubectl get storageclass
l01_reset: node                     ./lab list
```
`kubectl create deployment hello --image=... --replicas=2 --port=8080` + `kubectl expose deployment hello
--port=80 --target-port=8080`.

**Takeaways**
- Two worlds: the **kit** (`k8slab.bat` on Windows) creates, starts, snapshots VMs; **`./lab`** on this
  desktop does everything inside them (provision, build, labs, resets) over SSH. A broken VM is the kit's
  job (`k8slab.bat restore baseline`); everything else is `./lab cluster reset`.
- kubectl talks to `https://192.168.56.20:6443` - haproxy on k8s-gw - which forwards to the real API
  server on k8s-cp1. The kubeadm `controlPlaneEndpoint` is `k8s-api.lab:6443`: an extra control plane
  later is one more haproxy `server` line.
- Every node has two NICs: NAT (`10.0.2.15` on *every* VM - useless for cluster traffic) and host-only
  (192.168.56.x). kubelet `--node-ip`, the API advertise address and Calico are pinned to host-only (T03).
- Reset ladder: a lab is cleaned up at the level it declares - namespaces only, a node's files, gw's data,
  or the whole cluster (etcd restore from the golden on this desktop, ~1 min).
