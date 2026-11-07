deploy_stack
retry 60 svc_converged app_web
# wait until the disk is full (health turns 503)
retry 90 sh -c "! curl -fs --max-time 3 http://172.30.0.11:$APP_PORT/health"
