ws_sed 's/memory: 48G/memory: 128M/'
deploy_stack
retry 60 svc_converged app_reports
