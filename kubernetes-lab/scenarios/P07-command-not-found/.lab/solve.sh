sed -i '/command: \[gunicorn/d' reports.yaml
kx apply -f reports.yaml >/dev/null
wait_rollout reports deploy/reports
