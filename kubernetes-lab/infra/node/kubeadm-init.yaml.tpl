# kubeadm init config for k8s-cp1 (rendered by ./lab cluster build into /etc/kubernetes/kubeadm/init.yaml)
apiVersion: kubeadm.k8s.io/v1beta4
kind: InitConfiguration
localAPIEndpoint:
  advertiseAddress: @CP_IP@            # host-only address; NIC1 (NAT) is 10.0.2.15 on every VM
  bindPort: 6443
nodeRegistration:
  name: @CP@
  criSocket: unix:///run/containerd/containerd.sock
  kubeletExtraArgs:
    - name: node-ip
      value: @CP_IP@
---
apiVersion: kubeadm.k8s.io/v1beta4
kind: ClusterConfiguration
clusterName: lab
kubernetesVersion: v@VERSION@
controlPlaneEndpoint: @API_ENDPOINT@   # haproxy on k8s-gw -> k8s-cp1 (HA control planes can be added later)
networking:
  podSubnet: @POD_CIDR@
  serviceSubnet: @SERVICE_CIDR@
  dnsDomain: cluster.local
apiServer:
  certSANs: [k8s-api.lab, 192.168.56.20, @CP@, @CP_IP@]
---
apiVersion: kubelet.config.k8s.io/v1beta1
kind: KubeletConfiguration
cgroupDriver: systemd
serverTLSBootstrap: true               # real kubelet serving certs (CSRs approved by ./lab), metrics-server verifies them
---
apiVersion: kubeproxy.config.k8s.io/v1alpha1
kind: KubeProxyConfiguration
mode: iptables
