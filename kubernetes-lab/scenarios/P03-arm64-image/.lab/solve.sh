kx -n analytics set image deploy/etl etl=registry.lab:5000/lab/labapp:1.4 >/dev/null
wait_rollout analytics deploy/etl 180
