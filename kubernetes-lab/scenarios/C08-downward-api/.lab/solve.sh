sed -i 's/fieldPath: status.podIp}/fieldPath: status.podIP}/; s/resources: {requests: {cpu: 50m, memory: 64Mi}}/resources: {requests: {cpu: 50m, memory: 64Mi}, limits: {memory: 256Mi}}/' inventory.yaml
kx apply -f inventory.yaml >/dev/null
wait_rollout inventory deploy/inventory 180
