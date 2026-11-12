sed -i 's/, hostPort: 9100}/}/' edge-proxy.yaml
kx apply -f edge-proxy.yaml >/dev/null
wait_rollout edge deploy/edge-proxy
