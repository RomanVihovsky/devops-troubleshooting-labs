# T08: something precious in t08; no snapshot or restored data dir from an earlier run
nx "$CP" 'rm -rf /var/backups/etcd-t08.db /var/lib/etcd-t08' </dev/null
kns t08
kx -n t08 create configmap precious --from-literal=owner=finance --from-literal=note="do not lose me" >/dev/null
remember t08_ns_uid "$(kx get namespace t08 -o jsonpath='{.metadata.uid}')"
remember t08_cm_uid "$(kx -n t08 get configmap precious -o jsonpath='{.metadata.uid}')"
# the inode of etcd's member dir: a restore creates a new one (the cluster ID would not change - it is
# derived from the member name, peer URL and cluster token, which a proper restore keeps)
remember t08_member_inode "$(nx "$CP" 'stat -c %i /var/lib/etcd/member' </dev/null)"
[ -n "$(recall t08_member_inode)" ] || die "could not stat etcd's data dir"
