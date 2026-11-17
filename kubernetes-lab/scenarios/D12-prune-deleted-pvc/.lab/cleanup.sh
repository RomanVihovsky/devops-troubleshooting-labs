# Retain volumes outlive the namespace: delete the PVs of nfs-retain and their directories on gw's export
for pv in $(kx get pv -o json 2>/dev/null | jq -r '.items[] | select(.spec.storageClassName == "nfs-retain") | .metadata.name'); do
  h=$(kx get pv "$pv" -o jsonpath='{.spec.csi.volumeHandle}' 2>/dev/null)   # server#share#subdir#...
  IFS='#' read -r _ share sub _ <<<"$h"
  kx delete pv "$pv" --wait=false >/dev/null 2>&1 || true
  case $sub in pvc-*) nx k8s-gw "rm -rf /${share#/}/$sub" </dev/null >/dev/null 2>&1 || true ;; esac
done
kx delete storageclass nfs-retain --ignore-not-found >/dev/null 2>&1
true
