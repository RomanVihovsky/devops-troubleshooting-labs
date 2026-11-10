sed -i 's/cpu: "16"/cpu: 100m/' render.yaml
kx apply -f render.yaml >/dev/null
wait_rollout render deploy/render
