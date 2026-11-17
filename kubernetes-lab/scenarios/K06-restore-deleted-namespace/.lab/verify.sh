api_ok() { kx get --raw /readyz >/dev/null 2>&1; }
uid_is() { local ns=$1 o=$2 k=$3; [ "$(kx $ns get "$o" -o jsonpath='{.metadata.uid}' 2>/dev/null)" = "$(recall "$k")" ]; }
objects_back() {
  uid_is "" namespace/prod k06_namespace && uid_is -nprod deploy/orders k06_deploy \
    && uid_is -nprod configmap/orders-config k06_configmap && uid_is -nprod secret/orders-db k06_secret \
    && [ "$(kx -n prod get configmap orders-config -o jsonpath='{.data.currency}')" = EUR ] \
    && [ "$(kx -n prod get secret orders-db -o jsonpath='{.data.password}')" = "$(recall k06_pw)" ]
}
member_inode() {
  nx "$CP" "python3 -c 'import yaml; d = yaml.safe_load(open(\"/etc/kubernetes/manifests/etcd.yaml\"))
print([v[\"hostPath\"][\"path\"] for v in d[\"spec\"][\"volumes\"] if v[\"name\"] == \"etcd-data\"][0])' | xargs -I{} stat -c %i {}/member" </dev/null
}
restored() { local i; i=$(member_inode); [ -n "$i" ] && [ "$i" != "$(recall k06_inode)" ]; }
manifests4() { [ "$(nx "$CP" 'ls /etc/kubernetes/manifests | wc -l' </dev/null)" = 4 ]; }
check_eventually 180 "the API answers" api_ok
check "prod, orders, orders-config and orders-db are back with their original UIDs and data" objects_back
check_eventually 180 "orders: 2 Ready pods" deploy_ready prod orders 2
check "etcd runs from restored data (a new member dir)" restored
check_eventually 180 "all nodes Ready" nodes_ready
check "only the 4 control-plane manifests in /etc/kubernetes/manifests" manifests4
verdict
