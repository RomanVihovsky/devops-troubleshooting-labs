# V08: the running Deployment still mounts the old claim; the claim was deleted -> pvc-protection holds it
kns forms
sed 's/claimName: forms-data-v2/claimName: forms-data/; s/name: forms-data-v2, namespace/name: forms-data, namespace/' forms.yaml | ka -f -
wait_rollout forms deploy/forms
kx -n forms delete pvc forms-data --wait=false >/dev/null
term() { [ -n "$(kx -n forms get pvc forms-data -o jsonpath='{.metadata.deletionTimestamp}')" ]; }
retry 30 term || die "PVC not Terminating"
