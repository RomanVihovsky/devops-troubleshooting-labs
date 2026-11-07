dk node update --label-add disk=ssd worker2 >/dev/null
retry 60 svc_converged app_db
