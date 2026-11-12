one_default() { [ "$(kx get storageclass -o json | jq '[.items[] | select(.metadata.annotations["storageclass.kubernetes.io/is-default-class"] == "true")] | length')" = 1 ]; }
bound() { [ "$(kx -n wiki get pvc wiki-data -o jsonpath='{.status.phase}' 2>/dev/null)" = Bound ]; }
no_class_in_manifest() { ! grep -q storageClassName wiki.yaml; }
check "exactly one default StorageClass" one_default
check_eventually 120 "PVC wiki-data Bound" bound
check_eventually 120 "wiki runs" deploy_ready wiki wiki
check "wiki.yaml still names no storage class" no_class_in_manifest
verdict
