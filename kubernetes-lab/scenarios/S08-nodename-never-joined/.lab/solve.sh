sed -i '/nodeName: k8s-w4/d' legacy-sync.yaml
kx apply -f legacy-sync.yaml >/dev/null
wait_rollout legacy deploy/legacy-sync
