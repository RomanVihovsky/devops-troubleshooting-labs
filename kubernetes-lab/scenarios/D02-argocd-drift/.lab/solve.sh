argo_sync demo
retry 180 argo_app_ok demo || true
# GREETING was never in Git: the sync's three-way merge keeps it and Argo CD doesn't count it as drift
kx -n demo set env deploy/demo GREETING- >/dev/null
wait_rollout demo deploy/demo
retry 180 argo_app_ok demo || true
