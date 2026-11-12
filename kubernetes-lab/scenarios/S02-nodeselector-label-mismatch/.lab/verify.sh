on_ssd() { [ "$(kx -n indexer get pods -l app=indexer --field-selector=status.phase=Running -o jsonpath='{.items[*].spec.nodeName}' 2>/dev/null)" = k8s-w2 ]; }
labels_same() {
  [ "$(kx get nodes -o json | jq -c '[.items[] | {n: .metadata.name, d: .metadata.labels.disk, t: .metadata.labels.disktype}] | sort_by(.n)')" \
    = '[{"n":"k8s-cp1","d":null,"t":null},{"n":"k8s-w1","d":null,"t":null},{"n":"k8s-w2","d":"ssd","t":null},{"n":"k8s-w3","d":null,"t":null}]' ]
}
check_eventually 120 "indexer rollout complete, Ready" deploy_ready indexer indexer
check "indexer runs on the SSD node (k8s-w2)" on_ssd
check "node labels unchanged (only k8s-w2 has disk=ssd)" labels_same
verdict
