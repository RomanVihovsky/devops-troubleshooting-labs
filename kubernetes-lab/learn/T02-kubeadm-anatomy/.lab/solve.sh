source "$SCN/.lab/facts.sh"
cat > answers.yaml <<YML
cgroup_driver: $(f_cgroup_driver)
static_pod_path: $(f_static_pod_path)
node_ip_file: $(f_node_ip_file)
kubelet_server: $(f_kubelet_server)
admin_group: "$(f_admin_group)"
etcd_data_dir: $(f_etcd_data_dir)
ca_expiry_year: $(f_ca_expiry_year)
service_cidr: $(f_service_cidr)
YML
