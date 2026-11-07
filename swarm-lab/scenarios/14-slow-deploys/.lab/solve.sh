ws_sed '/entrypoint: \["\/app\/start.sh"\]/d'
deploy_stack
sleep 3
retry 180 svc_converged app_web
