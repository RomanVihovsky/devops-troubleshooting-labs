sed -i 's/requests: {cpu: 50m, memory: 128Mi}/requests: {cpu: 50m, memory: 320Mi}/; s/limits: {memory: 128Mi}/limits: {memory: 320Mi}/' cache.yaml
kx apply -f cache.yaml >/dev/null
wait_rollout search-cache deploy/search-cache
