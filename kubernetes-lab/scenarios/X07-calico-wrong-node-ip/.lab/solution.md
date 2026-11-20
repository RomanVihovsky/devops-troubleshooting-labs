# X07 - Calico autodetected the wrong node address

**Root cause**: calico-node finds the node's address with `IP_AUTODETECTION_METHOD`. It was changed from
`cidr=192.168.56.0/24` to `can-reach=1.1.1.1`, which takes the source address of the route to 1.1.1.1: the default
route, i.e. the VirtualBox **NAT** NIC (`enp0s3`, `10.0.2.15` on every VM). With `updateStrategy: OnDelete` only the restarted pod (w3) used it: w3 registered
`10.0.2.15` as its VXLAN tunnel endpoint, so every other node encapsulates traffic for w3's pods to 10.0.2.15 - which
is themselves.

**Diagnosis**
```
kubectl get nodes -o custom-columns=NAME:.metadata.name,IP:.metadata.annotations.projectcalico\.org/IPv4Address
kubectl -n kube-system get ds calico-node -o yaml | grep -A1 -E 'IP_AUTODETECTION|updateStrategy' 
kubectl -n kube-system logs -l k8s-app=calico-node --field-selector spec.nodeName=k8s-w3 -c calico-node | grep -i autodetect
```

**Fix**: `IP_AUTODETECTION_METHOD=cidr=192.168.56.0/24` (or `interface=enp0s8` / `kubernetes-internal-ip`), back to
`RollingUpdate`, recreate w3's pod. With OnDelete a "safe" change silently lands node by node as pods restart -
that's how only one node broke.

**Interview notes**
- Multi-NIC nodes (VirtualBox NAT, cloud secondary ENIs, Docker bridges) need an explicit autodetection method -
  same for the kubelet's `--node-ip` (L06).
- Other methods: `can-reach=<ip>`, `skip-interface=<regex>`, `kubernetes-internal-ip`.
- OnDelete is for components that must be restarted in a controlled order (some CNIs, storage); it hides drift.
