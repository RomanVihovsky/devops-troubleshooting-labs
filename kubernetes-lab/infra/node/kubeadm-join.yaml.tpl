# kubeadm join config for a worker (rendered by ./lab cluster build into /etc/kubernetes/kubeadm/join.yaml)
apiVersion: kubeadm.k8s.io/v1beta4
kind: JoinConfiguration
discovery:
  bootstrapToken:
    apiServerEndpoint: @API_ENDPOINT@
    token: @TOKEN@
    caCertHashes: [@CA_HASH@]
nodeRegistration:
  name: @NODE@
  criSocket: unix:///run/containerd/containerd.sock
  kubeletExtraArgs:
    - name: node-ip
      value: @NODE_IP@
