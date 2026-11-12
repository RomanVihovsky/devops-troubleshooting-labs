# T02: the live truth behind the answers (sourced by verify and solve)
f_cgroup_driver() { nx k8s-w1 "awk '/^cgroupDriver:/ { print \$2 }' /var/lib/kubelet/config.yaml" </dev/null; }
f_static_pod_path() { nx k8s-w1 "awk '/^staticPodPath:/ { print \$2 }' /var/lib/kubelet/config.yaml" </dev/null; }
f_node_ip_file() { nx k8s-w1 'grep -l -- --node-ip /var/lib/kubelet/kubeadm-flags.env /etc/default/kubelet 2>/dev/null | head -1' </dev/null; }
f_kubelet_server() { nx k8s-w1 "awk '/server:/ { print \$2 }' /etc/kubernetes/kubelet.conf" </dev/null; }
f_admin_group() {
  nx "$CP" "awk '/client-certificate-data/ { print \$2 }' /etc/kubernetes/admin.conf | base64 -d | openssl x509 -noout -subject -nameopt sep_multiline" </dev/null \
    | sed -n 's/^ *O=//p' | head -1
}
f_etcd_data_dir() { nx "$CP" "grep -o -- '--data-dir=[^ ]*' /etc/kubernetes/manifests/etcd.yaml | cut -d= -f2" </dev/null; }
f_ca_expiry_year() { nx "$CP" "date -d \"\$(openssl x509 -enddate -noout -in /etc/kubernetes/pki/ca.crt | cut -d= -f2)\" +%Y" </dev/null; }
f_service_cidr() { kx -n kube-system get cm kubeadm-config -o jsonpath='{.data.ClusterConfiguration}' | awk '/serviceSubnet:/ { print $2 }'; }
