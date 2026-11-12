# V07: a copy of the nfs StorageClass with allowVolumeExpansion: false - growing its claims is refused
kx get storageclass nfs -o json | jq '{apiVersion, kind, metadata: {name: "nfs-standard"}, provisioner, parameters,
  reclaimPolicy, volumeBindingMode, mountOptions, allowVolumeExpansion: false} | with_entries(select(.value != null))' | ka -f -
kns archive
ka -f archive.yaml
wait_rollout archive deploy/archive
v="archived-$(openssl rand -hex 6)"; remember v07_value "$v"
kx -n archive exec deploy/archive -- labapp get -X PUT -d "$v" http://localhost:8080/kv/report-2026 >/dev/null
remember v07_pv "$(kx -n archive get pvc archive-data -o jsonpath='{.spec.volumeName}')"
sed -i 's/storage: 1Gi/storage: 2Gi/' archive.yaml
! kx apply -f archive.yaml >/dev/null 2>&1 || die "the resize was accepted"
