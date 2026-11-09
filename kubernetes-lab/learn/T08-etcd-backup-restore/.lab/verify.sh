snap_ok() { nx "$CP" 'test -s /var/backups/etcd-t08.db && etcdutl snapshot status /var/backups/etcd-t08.db >/dev/null 2>&1' </dev/null; }
# the data dir etcd's static pod mounts (hostPath of the etcd-data volume) and the inode of its member dir
member_inode() {
  nx "$CP" "python3 -c 'import yaml; d = yaml.safe_load(open(\"/etc/kubernetes/manifests/etcd.yaml\"))
print([v[\"hostPath\"][\"path\"] for v in d[\"spec\"][\"volumes\"] if v[\"name\"] == \"etcd-data\"][0])' | xargs -I{} stat -c %i {}/member" </dev/null
}
restored() { local i; i=$(member_inode); [ -n "$i" ] && [ "$i" != "$(recall t08_member_inode)" ]; }
api_ok() { kx get --raw /readyz >/dev/null 2>&1; }
ns_back() { [ "$(kx get namespace t08 -o jsonpath='{.metadata.uid}' 2>/dev/null)" = "$(recall t08_ns_uid)" ]; }
cm_back() {
  [ "$(kx -n t08 get configmap precious -o jsonpath='{.metadata.uid} {.data.owner}' 2>/dev/null)" = "$(recall t08_cm_uid) finance" ]
}
manifests4() { [ "$(nx "$CP" 'ls /etc/kubernetes/manifests | wc -l' </dev/null)" = 4 ]; }
check "snapshot /var/backups/etcd-t08.db exists and is valid" snap_ok
check_eventually 180 "the API answers" api_ok
check "etcd runs from restored data (a new member dir)" restored
check "namespace t08 is back with its original UID" ns_back
check "ConfigMap precious is back with its original UID and data" cm_back
check_eventually 180 "all nodes Ready" nodes_ready
check "only the 4 control-plane manifests in /etc/kubernetes/manifests" manifests4
verdict
