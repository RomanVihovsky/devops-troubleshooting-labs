sed -i '/schedulerName: gpu-scheduler/d' ml-api.yaml
kx apply -f ml-api.yaml >/dev/null
wait_rollout ml deploy/ml-api
