kx -n pay patch deploy checkout -p '{"spec":{"revisionHistoryLimit":10}}' >/dev/null
kx -n pay set image deploy/checkout labapp=registry.lab:5000/lab/labapp:1.3 >/dev/null
kx -n pay set env deploy/checkout ERROR_RATE- >/dev/null
wait_rollout pay deploy/checkout 180
