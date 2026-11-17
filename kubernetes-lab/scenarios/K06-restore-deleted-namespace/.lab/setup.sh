# K06: a real backup of the cluster, then `kubectl delete ns prod`
nx "$CP" 'rm -rf /var/backups/etcd /var/lib/etcd-restored /var/lib/etcd-prod' </dev/null
kns prod
kx -n prod create configmap orders-config --from-literal=currency=EUR --from-literal=tax_rate=0.21 --dry-run=client -o yaml | ka -f -
kx -n prod create secret generic orders-db --from-literal=password="$(openssl rand -hex 12)" --dry-run=client -o yaml | ka -f -
kx -n prod create deployment orders --image=registry.lab:5000/lab/labapp:1.4 --replicas=2 --dry-run=client -o yaml | ka -f -
wait_rollout prod deploy/orders
for o in namespace/prod deploy/orders configmap/orders-config secret/orders-db; do
  ns=-nprod; [ "$o" = namespace/prod ] && ns=""
  # shellcheck disable=SC2086
  remember "k06_$(echo "${o%/*}" | tr -d -)" "$(kx $ns get "$o" -o jsonpath='{.metadata.uid}')"
done
remember k06_pw "$(kx -n prod get secret orders-db -o jsonpath='{.data.password}')"
remember k06_inode "$(nx "$CP" 'stat -c %i /var/lib/etcd/member' </dev/null)"
nx "$CP" "mkdir -p /var/backups/etcd && etcdctl $ETCD_FLAGS snapshot save /var/backups/etcd/etcd-nightly.db >/dev/null 2>&1" </dev/null
kx delete namespace prod --wait=true --timeout=180s >/dev/null
! kx get namespace prod >/dev/null 2>&1 || die "prod still exists"
