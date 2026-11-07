ws_sed 's/memory: 128M/memory: 384M/'
deploy_stack
retry 90 svc_converged app_web
