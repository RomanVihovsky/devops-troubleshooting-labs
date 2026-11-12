sed -i 's/labelSelector: {matchLabels: {app: cache}}/labelSelector: {matchLabels: {app: redis-cache}}/' sessions.yaml
kx apply -f sessions.yaml >/dev/null
wait_rollout sessions deploy/session-api 120 || true
