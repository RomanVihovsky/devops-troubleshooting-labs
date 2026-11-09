# T05: a Retain PV outlives its namespace - delete the namespace first, then the released PVs and their data
kx delete namespace t05 --ignore-not-found --wait=false >/dev/null 2>&1
kx wait --for=delete namespace/t05 --timeout=120s >/dev/null 2>&1
kx get pv -o json | jq -r '.items[] | select(.spec.claimRef.namespace == "t05")
  | [.metadata.name, (.spec.nodeAffinity.required.nodeSelectorTerms[0].matchExpressions[0].values[0] // ""),
     (.spec.local.path // .spec.hostPath.path // "")] | @tsv' |
while IFS=$'\t' read -r pv node path; do
  kx delete pv "$pv" --wait=false >/dev/null 2>&1
  case $path in /opt/local-path-provisioner/pvc-*) [ -n "$node" ] && nx "$node" "rm -rf '$path'" </dev/null ;; esac
done
true
